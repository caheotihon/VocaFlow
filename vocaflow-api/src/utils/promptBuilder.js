/**
 * PromptBuilder utility for AI Story generation
 * Builds Gemini prompts with anti-list rules and detects vocabulary list patterns
 */

/**
 * Builds the primary Gemini prompt with anti-list rules
 * @param {Array<{word: string, meaning_vn: string, definition_en: string}>} words
 * @param {boolean} reinforced - true for retry with stronger instructions
 * @returns {string} prompt string
 */
function buildStoryPrompt(words, reinforced = false) {
  const wordDetails = words
    .map((w) => `- "${w.word}" (Vietnamese: ${w.meaning_vn}; English: ${w.definition_en})`)
    .join('\n');

  let prompt = `You are a professional English teacher and creative writer.

Write an engaging short story (150-250 words) in English that naturally incorporates the following vocabulary words:

${wordDetails}

CRITICAL RULES — you MUST follow all of these:
1. Each vocabulary word MUST appear naturally within a sentence, woven into the narrative.
2. NEVER list vocabulary words in a comma-separated or semicolon-separated sequence at any point in the story.
3. Distribute vocabulary words across DIFFERENT sentences and paragraphs — no more than 2 vocabulary words may appear in the same sentence.
4. Use each word in a context that reflects its meaning as provided above.
5. The story must flow naturally as a coherent narrative, not as a vocabulary exercise.
6. Do NOT include any section like "Vocabulary used:", "Words in this story:", or any enumeration of the words.
7. Never use a phrase such as "these words:" or "the following words:" followed by a list or comma-separated sequence.
8. Do NOT provide links, anchors, or markup that exposes the raw vocabulary list.
9. If you would otherwise be tempted to summarize the words, instead weave each word into its own natural example sentence within the narrative.
10. Create a story with a UNIQUE plot, setting, and characters — vary the narrative structure each time.
11. Avoid repetitive templates; make each story feel fresh and different from typical vocabulary exercises.`;

  if (reinforced) {
    prompt += `\n\nIMPORTANT REMINDER: Do NOT write the vocabulary words as a list anywhere in the story. DO NOT use 'these words:' or similar constructions. If the model would list, instead place each word inside a natural sentence that demonstrates its meaning.`;
  }

  prompt += `\n\nReturn a raw JSON object (no markdown wrappers):
{
  "title": "...",
  "story": "...",
  "quiz": [{ "question": "...", "options": [...], "answerIndex": 0, "explanation": "..." }]
}`;

  return prompt;
}

/**
 * Detects if story content contains vocabulary list pattern
 * (3+ selected words appearing consecutively separated by commas/semicolons)
 * @param {string} content - story text
 * @param {string[]} wordNames - list of vocabulary word strings
 * @returns {boolean}
 */
function hasVocabListPattern(content, wordNames) {
  if (!content || !wordNames || wordNames.length < 3) {
    return false;
  }

  // Escape special regex characters in each word name
  const escapedWords = wordNames.map((w) =>
    w.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  );

  // Build a pattern that matches 3 or more vocabulary words appearing consecutively,
  // separated ONLY by commas or semicolons (with optional surrounding whitespace).
  // Each separator is: optional whitespace, comma or semicolon, optional whitespace.
  const separator = '[,;]\\s*';
  const wordPattern = `(?:${escapedWords.join('|')})`;

  // Pattern: wordPattern followed by (separator + wordPattern) repeated 2+ more times
  // This ensures at least 3 consecutive vocab words separated only by commas/semicolons
  const listPattern = new RegExp(
    `(?<![\\w])${wordPattern}(?:\\s*${separator}${wordPattern}){2,}(?![\\w])`,
    'i'
  );

  return listPattern.test(content);
}

module.exports = { buildStoryPrompt, hasVocabListPattern };
