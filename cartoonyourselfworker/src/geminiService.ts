interface GeminiResponse {
	candidates?: Array<{
		content?: {
			parts?: Array<{
				text?: string;
				inlineData?: {
					data: string;
				};
			}>;
		};
	}>;
	promptFeedback?: any;
}

export class GeminiService {
	private apiKey: string;

	constructor(apiKey: string) {
		if (!apiKey) {
			throw new Error('Gemini API key is required');
		}
		this.apiKey = apiKey;
	}

	/**
	 * Analyzes an image and returns a description of its content
	 * 
	 * @param imageData - The image data as a buffer
	 * @param mimeType - The MIME type of the image
	 * @returns A description of the image content
	 */
	async analyzeImage(imageData: ArrayBuffer, mimeType: string): Promise<string> {
		try {
			// Convert ArrayBuffer to base64
			const base64Image = this.arrayBufferToBase64(imageData);

			const prompt = `This is a realistic ai generated photo, you are a helper that ensures we dont replicate this photo by accident.
Example:
<sample>
The image shows someone with long blonde hair that transitions from darker roots to lighter ends sitting at what appears to be a cafe table. They're wearing a beige/cream-colored sweater with a high neckline. The person is smiling at the camera and has a coffee cup with latte art in front of them on a wooden table.
In the background, there's a city street visible through what seems to be a cafe window, with a white car parked outside and some buildings. The setting has an urban feel with trees visible and a slightly blurred cityscape behind the person.
</sample>

To ensure we do not replicate this photo describe the people in this image as well as the background. Focus on facial expressions and clothing. Output only text, no markdown or other formatting. About 300 words. Single paragraph.`;

			const requestBody = {
				contents: [{
					role: "user",
					parts: [
						{
							inline_data: {
								mime_type: mimeType,
								data: base64Image
							}
						},
						{
							text: prompt
						}
					]
				}],
				generationConfig: {
					temperature: 0.4,
					topP: 0.95,
					topK: 40,
					maxOutputTokens: 1024,
				}
			};

			const apiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=${this.apiKey}`;

			const response = await fetch(apiUrl, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
				},
				body: JSON.stringify(requestBody)
			});

			if (!response.ok) {
				const errorText = await response.text();
				console.error('Gemini API error:', {
					status: response.status,
					statusText: response.statusText,
					error: errorText
				});

				// For rate limit errors (HTTP 429)
				if (response.status === 429) {
					const rateLimitError = new Error('Gemini API rate limit exceeded');
					rateLimitError.name = 'GeminiRateLimitError';
					throw rateLimitError;
				}

				throw new Error(`Failed to analyze image: ${response.status} ${response.statusText}`);
			}

			const data = await response.json();
			const responseData = data as GeminiResponse;

			// Extract the text response
			const textResponse = responseData.candidates?.[0]?.content?.parts?.[0]?.text;
			if (!textResponse) {
				console.error('No text data in response:', data);
				throw new Error('No text data in response');
			}

			// Ensure we have a consistent format by replacing newlines with spaces
			return textResponse.replace(/\n/g, ' ');
		} catch (error) {
			console.error("Error analyzing image with Gemini:", error);
			throw new Error(`Gemini image analysis failed: ${error instanceof Error ? error.message : String(error)}`);
		}
	}

	/**
	 * Processes an image using Gemini's image generation capabilities
	 * 
	 * @param imageData - The image data as a buffer
	 * @param mimeType - The MIME type of the image
	 * @param prompt - The prompt to guide image generation
	 * @returns The processed image as an ArrayBuffer
	 */
	async processImage(imageData: ArrayBuffer, mimeType: string, prompt: string): Promise<ArrayBuffer> {
		// Convert ArrayBuffer to base64
		const base64Image = this.arrayBufferToBase64(imageData);

		const requestBody = {
			contents: [{
				role: "user",
				parts: [
					{
						inline_data: {
							mime_type: mimeType,
							data: base64Image
						}
					},
					{
						text: prompt
					}
				]
			}],
			generationConfig: {
				temperature: 1,
				topP: 0.95,
				topK: 40,
				maxOutputTokens: 8192,
				responseModalities: ["Text", "Image"]
			}
		};

		// const apiUrl = `https://gemini-proxy-9wtm.onrender.com/api/gemini/generate-image`;
		const apiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp-image-generation:generateContent?key=${this.apiKey}`;

		const response = await fetch(apiUrl, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
			},
			body: JSON.stringify(requestBody)
		});

		if (!response.ok) {
			const errorText = await response.text();
			console.error('Gemini API error:', {
				status: response.status,
				statusText: response.statusText,
				error: errorText
			});

			// For rate limit errors (HTTP 429)
			if (response.status === 429) {
				const rateLimitError = new Error('Gemini API rate limit exceeded');
				rateLimitError.name = 'GeminiRateLimitError';
				throw rateLimitError;
			}

			throw new Error(`Failed to process image: ${response.status} ${response.statusText}`);
		}

		const data = await response.json();
		const responseData = data as GeminiResponse;

		// Extract the image data
		const base64ResponseImage = responseData.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;
		if (!base64ResponseImage) {
			//log other data
			console.log(data);
			console.error('No image data in response:', data);
			throw new Error('No image data in response');
		}

		// Convert base64 back to ArrayBuffer
		return this.base64ToArrayBuffer(base64ResponseImage);
	}

	private arrayBufferToBase64(buffer: ArrayBuffer): string {
		const bytes = new Uint8Array(buffer);
		const binary = bytes.reduce((acc, byte) => acc + String.fromCharCode(byte), '');
		return btoa(binary);
	}

	private base64ToArrayBuffer(base64: string): ArrayBuffer {
		const binaryString = atob(base64);
		const bytes = new Uint8Array(binaryString.length);
		for (let i = 0; i < binaryString.length; i++) {
			bytes[i] = binaryString.charCodeAt(i);
		}
		return bytes.buffer;
	}
}

export function createGeminiService(apiKey: string): GeminiService {
	return new GeminiService(apiKey);
} 