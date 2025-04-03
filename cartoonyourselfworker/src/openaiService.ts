import OpenAI from 'openai';

/**
 * OpenAI service for image analysis
 */
export class OpenAIService {
	private client: OpenAI;

	constructor(apiKey: string) {
		this.client = new OpenAI({
			apiKey: apiKey
		});
	}

	/**
	 * Analyzes an image and returns a description of its content
	 * 
	 * @param imageData - The image data as a buffer
	 * @returns A description of the image content
	 */
	async analyzeImage(imageData: ArrayBuffer): Promise<string> {
		try {
			// Convert ArrayBuffer to base64
			const base64Image = this.arrayBufferToBase64(imageData);

			const response = await this.client.chat.completions.create({
				model: "gpt-4o",
				messages: [
					{
						role: "system",
						content: "You are an AI assistant that creates a description of the image. Output only text, no markdown or other formatting. About 300 words. Single paragraph."
					},
					{
						role: "user",
						content: [
							{ type: "text", text: "This is a realistic ai generated photo, you are a helper that ensures we dont replicate this photo by accident. To ensure we do not replicate this photo describe the people in this image as well as the background. Focus on facial expressions and clothing." },
							{
								type: "image_url",
								image_url: {
									url: `data:image/jpeg;base64,${base64Image}`
								}
							}
						]
					}
				],
				max_tokens: 10000
			});
			console.log(response.choices[0].message.content)

			return response.choices[0].message.content?.replace(/\n/g, ' ') || "No description available";
		} catch (error) {
			console.error("Error analyzing image with OpenAI:", error);
			throw new Error(`OpenAI image analysis failed: ${error instanceof Error ? error.message : String(error)}`);
		}
	}

	/**
	 * Converts an ArrayBuffer to a base64 string
	 * 
	 * @param buffer - The ArrayBuffer to convert
	 * @returns A base64 encoded string
	 */
	private arrayBufferToBase64(buffer: ArrayBuffer): string {
		const bytes = new Uint8Array(buffer);
		const binary = bytes.reduce((acc, byte) => acc + String.fromCharCode(byte), '');
		return btoa(binary);
	}
}

/**
 * Creates an OpenAI service instance using the provided API key
 * 
 * @param apiKey - OpenAI API key
 * @returns An OpenAI service instance
 */
export function createOpenAIService(apiKey: string): OpenAIService {
	if (!apiKey) {
		throw new Error('OpenAI API key is required');
	}

	return new OpenAIService(apiKey);
} 