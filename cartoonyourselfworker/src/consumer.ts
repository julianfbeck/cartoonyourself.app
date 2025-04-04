import { Redis } from '@upstash/redis/cloudflare'
import { generatePrompt } from './promptGenerator';
import { createGeminiService } from './geminiService';

interface QueueMessage {
	image: {
		key: string;  // R2 object key
		mime_type: string;
	};
	styleID: string;
	userID: string;
	timestamp: number;
	requestId: string;
}

export interface Env {
	// Define the R2 bucket binding
	IMAGES: R2Bucket;
	// OpenAI API key for image analysis (kept for backward compatibility)
	OPENAI_API_KEY: string;
	// Gemini API key for image processing
	GOOGLE_API_KEY: string;
	UPSTASH_REDIS_REST_TOKEN: string;
}

export async function processQueue(batch: MessageBatch<QueueMessage>, env: Env): Promise<void> {
	// Initialize Redis client
	const redis = new Redis({
		url: "https://ample-raven-18694.upstash.io",
		token: env.UPSTASH_REDIS_REST_TOKEN,
	})

	// Process each message in the batch
	for (const message of batch.messages) {
		try {
			console.log(`Processing request ${message.body.requestId}`);

			// Update state to processing
			await redis.set(message.body.requestId, "processing");

			// Fetch the image from R2
			const imageObject = await env.IMAGES.get(message.body.image.key);
			if (!imageObject) {
				console.error(`Image not found in R2: ${message.body.image.key}`);
				await redis.set(message.body.requestId, "failed");
				message.ack();
				continue;
			}

			// Get the image data as an ArrayBuffer
			const imageData = await imageObject.arrayBuffer();

			// Create Gemini service for both image analysis and generation
			const geminiService = createGeminiService(env.GOOGLE_API_KEY);

			// Analyze the image using Gemini
			const imageContext = await geminiService.analyzeImage(imageData, message.body.image.mime_type);
			console.log(imageContext);

			// Generate the appropriate prompt based on styleID and image context
			const prompt = generatePrompt(message.body.styleID, imageContext);

			// Process the image with Gemini
			console.log('Processing image with Gemini...');
			const processedImageData = await geminiService.processImage(
				imageData,
				message.body.image.mime_type,
				prompt
			);

			// Store the processed image in R2
			const processedImageKey = `processed/${message.body.requestId}.png`;
			await env.IMAGES.put(processedImageKey, processedImageData, {
				httpMetadata: {
					contentType: 'image/png' // Gemini always returns PNG
				}
			});

			// Update state to completed
			await redis.set(message.body.requestId, "completed");

			// Acknowledge the message after successful processing
			message.ack();
		} catch (error) {
			console.error(`Error processing message ${message.body.requestId}:`, error);

			// Check if this is a rate limit error from Gemini
			if (error instanceof Error && (
				error.name === 'GeminiRateLimitError' ||
				(error.message && error.message.includes('429'))
			)) {
				console.log(`Rate limit hit for request ${message.body.requestId}, will retry automatically`);
				// Don't acknowledge the message - this will cause it to be retried
				return; // Exit the function without acknowledging
			}

			// For other errors, mark as failed and acknowledge
			await redis.set(message.body.requestId, "failed");
			await redis.expire(message.body.requestId, 60 * 60 * 24);
			message.ack();
		}
	}
} 