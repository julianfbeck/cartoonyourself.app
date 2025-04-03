interface GeminiResponse {
	candidates?: Array<{
		content?: {
			parts?: Array<{
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
			console.log(response.status);

			// For rate limit errors (HTTP 429)
			if (response.status === 429) {
				const rateLimitError = new Error('Gemini API rate limit exceeded');
				rateLimitError.name = 'GeminiRateLimitError'; // Changed name to be more specific
				throw rateLimitError;
			}

			throw new Error(`Failed to process image: ${response.status} ${response.statusText}`);
		}

		const data = await response.json();
		const responseData = data as GeminiResponse;

		// Extract the image data
		const base64ResponseImage = responseData.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;
		if (!base64ResponseImage) {
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