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
  "flat-01": {
    styleID: "flat-01",
    name: "Anime Default",
    prompt: "turn this into a cinematic cartoon style animation with a flat 2d presentation - no perspective Similar to South Park",
    styleJson:
      `<prompt>
  <style>South Park animation</style>
  <characters>
    <description>Original cartoon characters with the distinct South Park aesthetic</description>
    <features>
      <head>Oversized, round or oval shaped</head>
      <body>Small, simplistic, paper cut-out appearance</body>
      <limbs>Simple stick-like arms and legs</limbs>
      <faces>Minimalist features with basic eyes, small mouth, simple expressions</faces>
      <proportions>Exaggerated head-to-body ratio typical of South Park</proportions>
    </features>
    <clothing>Simple, flat colored outfits with minimal detail</clothing>
  </characters>
  <artStyle>
    <technique>Flat, cut-out paper animation look</technique>
    <colors>Bright, solid colors with minimal to no shading</colors>
    <linework>Simple black outlines</linework>
    <animation>Slightly crude, simplistic movements if animated</animation>
  </artStyle>
  <background>
    <importance>Minimal, simple background elements only</importance>
    <elements>Basic environmental indicators without elaborate detail</elements>
  </background>
  <restrictions>
    <avoid>Any copyrighted Pixar characters or specific locations</avoid>
    <avoid>Adding additional Characters that are not in the original image</avoid>
  </restrictions>
</prompt>`
  },
  "3d-animation-02": {
    styleID: "3d-animation-02",
    name: "Pixar 3D",
    prompt: "transform this into a high-quality 3D animation style similar to Pixar films with expressive characters and cinematic lighting. Only add characters that are in the original image.",
    styleJson: `<prompt>
  <style>Pixar animation</style>
  <characters>
    <description>Original cartoon characters with the distinct Pixar aesthetic</description>
    <features>
      <head>Slightly exaggerated proportions with expressive features</head>
      <body>Well-defined, believable anatomy with stylized proportions</body>
      <eyes>Large, expressive with detailed irises and reflective highlights</eyes>
      <skin>Subtle texturing with soft subsurface scattering effect</skin>
      <hair>Volumetric, physics-based appearance with natural movement</hair>
    </features>
    <expressions>Highly emotive, capable of nuanced feelings</expressions>
    <clothing>Detailed fabric with realistic folds, textures and light interaction</clothing>
  </characters>
  <artStyle>
    <technique>3D computer animation with physically-based rendering</technique>
    <lighting>Cinematic lighting with soft shadows and color theory</lighting>
    <colors>Rich color palette with vibrant but believable tones</colors>
    <rendering>Slightly stylized realism with attention to surface details</rendering>
    <animation>Squash and stretch principles with weight and momentum</animation>
  </artStyle>
  <background>
    <importance>Minimal, supporting elements only</importance>
    <elements>Suggested environment with depth but not detailed</elements>
    <lighting>Complementary to foreground characters</lighting>
  </background>
  <restrictions>
    <avoid>Any copyrighted Pixar characters or specific locations</avoid>
    <avoid>Adding additional Characters that are not in the original image</avoid>
  </restrictions>
</prompt>
`
  },
  "cartoon-03": {
    styleID: "cartoon-03",
    name: "Family Guy Style",
    prompt: "transform this into a 2D cartoon animation style similar to Family Guy with exaggerated characters and simple coloring. Only add characters that are in the original image.",
    styleJson: `<prompt>
  <style>Family Guy animation</style>
  <characters>
    <description>Original cartoon characters with the distinct Family Guy aesthetic</description>
    <features>
      <head>Round with prominent chin, oval or circular eyes</head>
      <body>Simple, somewhat bulbous torso with thin limbs</body>
      <eyes>Large, white oval eyes with black outlines, small pupils</eyes>
      <nose>Simple, often just a curved line or small bump</nose>
      <mouth>Wide, highly elastic for exaggerated expressions</mouth>
      <proportions>Exaggerated with oversized heads and simplified anatomy</proportions>
    </features>
    <expressions>Highly exaggerated, often deadpan or overly dramatic</expressions>
    <clothing>Simple, flat colored outfits with minimal shading and basic details</clothing>
  </characters>
  <artStyle>
    <technique>2D animation with clean lines and flat coloring</technique>
    <colors>Bright, saturated colors with minimal gradients</colors>
    <linework>Bold, consistent black outlines</linework>
    <animation>Snappy, often sudden movements if animated</animation>
    <style>Clean, cartoonish with minimal texture</style>
  </artStyle>
  <background>
    <importance>Minimal, simple background elements only</importance>
    <elements>Basic room interiors or simple outdoor scenes</elements>
    <style>Flat colors with minimal detail or depth</style>
  </background>
  <restrictions>
    <avoid>Any copyrighted Family Guy characters or specific locations</avoid>
    <avoid>Complex textures or realistic rendering</avoid>
    <avoid>Detailed backgrounds or environments</avoid>
    <avoid>Adding additional Characters that are not in the original image</avoid>
  </restrictions>
</prompt>
`
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
  return `${context}\n\n${style.prompt}\n\n\n${style.styleJson}\n`;
}

