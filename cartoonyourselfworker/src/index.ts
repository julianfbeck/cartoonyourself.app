/**
 * Welcome to Cloudflare Workers! This is your first worker.
 *
 * - Run `npm run dev` in your terminal to start a development server
 * - Open a browser tab at http://localhost:8787/ to see your worker in action
 * - Run `npm run deploy` to publish your worker
 *
 * Bind resources to your worker in `wrangler.jsonc`. After adding bindings, a type definition for the
 * `Env` object can be regenerated with `npm run cf-typegen`.
 *
 * Learn more at https://developers.cloudflare.com/workers/
 */

import { processQueue } from './consumer';
import { Redis } from '@upstash/redis/cloudflare'

/**
 * Cloudflare Worker that accepts image processing requests and puts them into a queue named "gemini"
 * for asynchronous processing.
 */

// Define the structure of the incoming request body
interface ImageData {
	data: string;
	mime_type: string;
}

interface RequestBody {
	image: ImageData;
	styleID: string;
	userID: string;
}

// Define the structure of messages we'll put in the queue
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

// Add rate limiting constants
const RATE_LIMIT = {
	MAX_REQUESTS: 20, // Maximum requests per window
	WINDOW_SECONDS: 3600, // Time window in seconds (1 hour)
};

export interface Env {
	// Define the R2 bucket binding
	IMAGES: R2Bucket;
	GEMINI: Queue;
	OPENAI_API_KEY: string;
	UPSTASH_REDIS_REST_TOKEN: string;
	GOOGLE_API_KEY: string;
	GOOGLE_API_KEY_2: string;
}

export default {
	// HTTP request handler
	async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
		const url = new URL(request.url);
		const requestId = url.pathname.split('/').pop(); // Get the last segment of the path

		// Initialize Redis client
		const redis = new Redis({
			url: "https://ample-raven-18694.upstash.io",
			token: env.UPSTASH_REDIS_REST_TOKEN,
		});

		// Handle status check endpoint
		if (url.pathname.startsWith('/v1/status/')) {
			if (!requestId) {
				return new Response(JSON.stringify({
					success: false,
					error: "Invalid status request"
				}), {
					headers: { 'Content-Type': 'application/json' },
					status: 400
				});
			}

			try {
				// Get the processing state from Redis
				const state = await redis.get(requestId);
				await redis.expire(requestId, 3600);

				if (!state) {
					return new Response(JSON.stringify({
						success: false,
						error: "Prediction not found"
					}), {
						headers: { 'Content-Type': 'application/json' },
						status: 404
					});
				}

				// If processing is still in the queue
				if (state === "queued" || state === "processing") {
					return new Response(JSON.stringify({
						success: true,
						data: {
							status: "pending"
						}
					}), {
						headers: { 'Content-Type': 'application/json' }
					});
				}

				// If processing failed
				if (state === "failed") {
					return new Response(JSON.stringify({
						success: true,
						data: {
							status: "failed"
						}
					}), {
						headers: { 'Content-Type': 'application/json' }
					});
				}

				// If processing is completed
				if (state === "completed") {
					const processedImageKey = `processed/${requestId}.png`;
					const processedImage = await env.IMAGES.get(processedImageKey);

					if (!processedImage) {
						return new Response(JSON.stringify({
							success: true,
							data: {
								status: "pending"
							}
						}), {
							headers: { 'Content-Type': 'application/json' }
						});
					}

					// Generate image URL
					const imageUrl = `https://gemini.app.juli.sh/processed/${requestId}.png`;

					console.log(imageUrl);
					console.log("Successfully generated image URL for requestId: ", requestId);
					// Return the processed image data
					return new Response(JSON.stringify({
						success: true,
						data: {
							status: "completed",
							id: requestId,
							url: imageUrl
						}
					}), {
						headers: { 'Content-Type': 'application/json' }
					});
				}

				// If we get here, it's an unknown state
				return new Response(JSON.stringify({
					success: true,
					data: {
						status: "pending"
					}
				}), {
					headers: { 'Content-Type': 'application/json' }
				});

			} catch (error) {
				console.error('Error checking status:', error);
				return new Response(JSON.stringify({
					success: false,
					error: "Error checking status",
					details: error instanceof Error ? error.message : String(error)
				}), {
					headers: { 'Content-Type': 'application/json' },
					status: 500
				});
			}
		}

		// Handle the original image processing endpoint
		if (url.pathname === '/v1/new') {
			// Generate a unique ID for this request
			const requestId = crypto.randomUUID();

			// Get client IP address
			const clientIP = request.headers.get('cf-connecting-ip') ||
				request.headers.get('x-forwarded-for') ||
				'unknown';

			// Check rate limit
			const rateLimitKey = `ratelimit:${clientIP}`;

			try {
				// Get current request count
				const requestCount = await redis.incr(rateLimitKey);

				// If this is the first request, set expiry
				if (requestCount === 1) {
					await redis.expire(rateLimitKey, RATE_LIMIT.WINDOW_SECONDS);
				}

				// Check if rate limit exceeded
				if (requestCount > RATE_LIMIT.MAX_REQUESTS) {
					// Get TTL for the rate limit key
					const ttl = await redis.ttl(rateLimitKey);

					return new Response(JSON.stringify({
						success: false,
						message: "Rate limit exceeded",
						requestId,
						resetIn: ttl,
						limitPerHour: RATE_LIMIT.MAX_REQUESTS
					}), {
						headers: {
							'Content-Type': 'application/json',
							'X-Request-ID': requestId,
							'X-RateLimit-Limit': RATE_LIMIT.MAX_REQUESTS.toString(),
							'X-RateLimit-Remaining': '0',
							'X-RateLimit-Reset': (Math.floor(Date.now() / 1000) + ttl).toString()
						},
						status: 429 // Too Many Requests
					});
				}

				// Add rate limit headers
				const remainingRequests = RATE_LIMIT.MAX_REQUESTS - requestCount;
				const ttl = await redis.ttl(rateLimitKey);
				const headers = {
					'Content-Type': 'application/json',
					'X-Request-ID': requestId,
					'X-RateLimit-Limit': RATE_LIMIT.MAX_REQUESTS.toString(),
					'X-RateLimit-Remaining': remainingRequests.toString(),
					'X-RateLimit-Reset': (Math.floor(Date.now() / 1000) + ttl).toString()
				};

				// Only allow POST requests
				if (request.method !== 'POST') {
					return new Response(JSON.stringify({
						success: false,
						message: "Only POST requests are accepted",
						requestId
					}), {
						headers,
						status: 405 // Method Not Allowed
					});
				}

				// Check if the path is correct
				if (url.pathname !== '/v1/new') {
					return new Response(JSON.stringify({
						success: false,
						message: "Not Found - Invalid endpoint",
						requestId
					}), {
						headers: {
							'Content-Type': 'application/json',
							'X-Request-ID': requestId
						},
						status: 404 // Not Found
					});
				}

				try {
					// Parse the request body
					const requestData: RequestBody = await request.json();

					// Validate the required fields
					if (!requestData.image || !requestData.image.data || !requestData.image.mime_type) {
						return new Response(JSON.stringify({
							success: false,
							message: "Missing required image data",
							requestId
						}), {
							headers: {
								'Content-Type': 'application/json',
								'X-Request-ID': requestId
							},
							status: 400 // Bad Request
						});
					}

					if (!requestData.styleID) {
						return new Response(JSON.stringify({
							success: false,
							message: "Missing required styleID",
							requestId
						}), {
							headers: {
								'Content-Type': 'application/json',
								'X-Request-ID': requestId
							},
							status: 400 // Bad Request
						});
					}

					if (!requestData.userID) {
						return new Response(JSON.stringify({
							success: false,
							message: "Missing required userID",
							requestId
						}), {
							headers: {
								'Content-Type': 'application/json',
								'X-Request-ID': requestId
							},
							status: 400 // Bad Request
						});
					}

					// Decode base64 image data
					const imageData = requestData.image.data.split(',')[1] || requestData.image.data;
					const binaryData = atob(imageData);
					const uint8Array = new Uint8Array(binaryData.length);
					for (let i = 0; i < binaryData.length; i++) {
						uint8Array[i] = binaryData.charCodeAt(i);
					}

					// Generate a unique key for the image in R2
					const imageKey = `${requestData.userID}/${requestId}`;

					// Upload the image to R2
					await env.IMAGES.put(imageKey, uint8Array, {
						httpMetadata: {
							contentType: requestData.image.mime_type
						}
					});

					// Store initial state in Redis
					await redis.set(requestId, "queued");

					// Create the message to be queued
					const message: QueueMessage = {
						image: {
							key: imageKey,
							mime_type: requestData.image.mime_type
						},
						styleID: requestData.styleID,
						userID: requestData.userID,
						timestamp: Date.now(),
						requestId
					};

					// Add the message to the gemini queue
					await env.GEMINI.send(message);

					// Return a success response with the request ID
					return new Response(JSON.stringify({
						success: true,
						message: "Image processing request queued successfully",
						requestId,
						imageKey,
						state: "queued"
					}), {
						headers,
						status: 202 // Accepted
					});
				} catch (error) {
					await redis.del(requestId);

					// Handle any errors
					console.error(`Error processing request: ${error}`);

					return new Response(JSON.stringify({
						success: false,
						message: "Failed to queue image processing request",
						error: error instanceof Error ? error.message : String(error),
						requestId,
						state: "failed"
					}), {
						headers: {
							'Content-Type': 'application/json',
							'X-Request-ID': requestId
						},
						status: 500
					});
				}
			} catch (error) {
				// If there's an error with rate limiting, proceed with the request
				console.error('Rate limiting error:', error);

				await redis.del(requestId);

				// Handle any errors
				console.error(`Error processing request: ${error}`);

				return new Response(JSON.stringify({
					success: false,
					message: "Failed to queue image processing request",
					error: error instanceof Error ? error.message : String(error),
					requestId,
					state: "failed"
				}), {
					headers: {
						'Content-Type': 'application/json',
						'X-Request-ID': requestId
					},
					status: 500
				});
			}
		}

		// Return 404 for any other routes
		return new Response(JSON.stringify({
			success: false,
			message: "Not Found - Invalid endpoint"
		}), {
			headers: { 'Content-Type': 'application/json' },
			status: 404
		});
	},

	// Queue message handler
	async queue(batch: MessageBatch<QueueMessage>, env: Env): Promise<void> {
		return processQueue(batch, env);
	}
};