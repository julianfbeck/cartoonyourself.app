/**
 * Prompt generator for AI image processing services
 */

interface StyleConfig {
  styleID: string;
  name: string;
  prompt: string;
  styleJson: string;
}

const STYLES: Record<string, StyleConfig> = {
  "anime-default-001": {
    styleID: "anime-default-001",
    name: "Anime Default",
    prompt: "turn this into a cinematic anime style animation",
    styleJson: `{
  "visualStyle": {
    "animation": {
      "technique": "cutout-style",
      "movement": "deliberately jerky and simplistic",
      "perspective": "flat, 2D presentation"
    },
    "characters": {
      "bodyType": "simple geometric shapes",
      "heads": "disproportionately large, often oval or circular",
      "limbs": "thin, often lacking detailed joints or musculature",
      "mouths": "simple lines that change shape without complex animation",
      "eyes": "basic dots or circles, minimal blinking animation"
    },
    "colorPalette": {
      "primary": "bright, saturated colors",
      "backgrounds": "simple, often with minimal detail",
      "snow": "abundant in many scenes, plain white",
      "outlines": "bold black lines around all elements"
    },
    "detailLevel": {
      "overall": "intentionally simplistic",
      "textures": "minimal to none",
      "shadows": "basic or absent",
      "background": "often recycled, minimal detail"
    },
    "cinematicElements": {
      "cameraWork": "limited movement, primarily static shots",
      "transitions": "simple cuts between scenes",
      "specialEffects": "deliberately crude when used"
    },
    "distinctiveFeatures": {
      "paperCutout": "appearance of paper cutouts moved frame by frame",
      "bobbing": "characters often bob up and down when speaking",
      "expressions": "limited range changed by swapping entire face elements",
      "proportions": "children characters shorter than adults but with similar head sizes",
      "mouthSyncing": "basic synchronization with dialogue"
    },
    "evolution": {
      "origins": "actual paper cutouts in early productions",
      "modern": "digital animation maintaining the paper cutout aesthetic"
    }
  },
}`

  },
  // Additional styles to be added later:
  // "cyberpunk-anime-003"
  // "chibi-kawaii-004"
  // "shoujo-soft-006"
  // "titan-dark-010"
};

/**
 * Generates a prompt for the AI service based on the given style ID and context
 * 
 * @param styleID - The ID of the style to use
 * @param context - The context to insert into the prompt
 * @returns The complete prompt with style JSON
 */
export function generatePrompt(styleID: string, context: string): string {
  const style = STYLES[styleID];

  if (!style) {
    throw new Error(`Style ID ${styleID} not found`);
  }

  // Context is now above the prompt, followed by the prompt, then style JSON without context
  return `${context}\n\n${style.prompt}\n\n\n<style>\n${style.styleJson}\n</style>`;
}

