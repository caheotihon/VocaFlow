const Story = require('../models/Story');
const Word = require('../models/Word');
const User = require('../models/User');
const { successResponse, errorResponse } = require('../utils/helpers');
const { buildStoryPrompt, hasVocabListPattern } = require('../utils/promptBuilder');
const axios = require('axios');

/**
 * Fallback static story generator with random variations when Gemini API is unavailable
 */
const generateFallbackStory = (wordsList) => {
  const wordNames = wordsList.map(w => w.word.toLowerCase());
  
  // Random story templates to vary output each time
  const titleTemplates = [
    `A Journey of Discovery`,
    `The Path to Mastery`,
    `Learning New Horizons`,
    `The Adventure Begins`,
    `Words That Connect`,
    `The Language Quest`,
    `Unlocking Communication`,
    `A New Chapter`
  ];
  const title = titleTemplates[Math.floor(Math.random() * titleTemplates.length)];
  
  // Vary story openings and contexts
  const openings = [
    `Once upon a time, a group of curious learners set out on an educational adventure.`,
    `In a vibrant classroom across the world, students gathered to embark on a linguistic quest.`,
    `Long ago, an ambitious team of language enthusiasts decided to explore new frontiers.`,
    `On a bright morning, a diverse group of learners convened with a shared mission.`
  ];
  const opening = openings[Math.floor(Math.random() * openings.length)];
  
  // Vary the narrative context
  const contexts = [
    `They wanted to understand the depth of human communication.`,
    `Their goal was to master the art of global communication.`,
    `They aimed to bridge cultural gaps through language learning.`,
    `They sought to unlock new opportunities through vocabulary mastery.`
  ];
  const context = contexts[Math.floor(Math.random() * contexts.length)];
  
  // Construct varied narrative without listing vocabulary as a comma-separated list
  const embeddedSentences = [];
  // Try to weave each word into a natural-sounding sentence using available definition if present
  for (let i = 0; i < wordsList.length; i++) {
    const w = wordsList[i];
    const name = w.word;
    const def = (w.definition_en || w.meaning_vn || '').replace(/\.$/, '');
    if (def) {
      embeddedSentences.push(`They often used ${name} in situations that matched its meaning — ${def}.`);
    } else {
      embeddedSentences.push(`They found ways to use ${name} naturally in conversation and writing.`);
    }
  }

  // Combine into a coherent story
  const story = `${opening} ${context} During their exploration, they realized that learning vocabulary is not just about memorizing words, but about using them in real context. ${embeddedSentences.join(' ')} Every day, they practiced diligently, knowing that each word they mastered would open new doors of opportunity in their lives. Eventually, their efforts paid off, and they became more fluent and confident in expressing their ideas to the world.`;

  const quiz = [
    {
      question: `What was the primary goal of the learners in the story?`,
      options: [
        `To travel around the world`,
        `To understand the depth of human communication and master vocabulary`,
        `To build a new library`,
        `To find a hidden treasure`
      ],
      answerIndex: 1,
      explanation: `Dựa vào câu chuyện: họ muốn hiểu sâu hơn về giao tiếp và thành thạo từ vựng.`
    },
    {
      question: `How did the story show the vocabulary words were learned?`,
      options: [
        `By listing them explicitly after a colon`,
        `By embedding each word naturally within sentences and examples`,
        `By presenting a separate vocabulary section`,
        `By only showing the words as headings`
      ],
      answerIndex: 1,
      explanation: `Câu chuyện mô tả cách sử dụng từng từ trong ngữ cảnh, không liệt kê chúng như một danh sách.`
    }
  ];

  return { title, story, quiz };
};

/**
 * POST /api/stories/generate
 * Generates an AI story using Gemini 1.5 Flash based on a list of wordIds
 */
exports.generateStory = async (req, res) => {
  try {
    const { wordIds } = req.body;
    if (!wordIds || !Array.isArray(wordIds) || wordIds.length < 2) {
      return errorResponse(res, 'At least 2 wordIds are required to generate a story', 400);
    }

    // 1. Fetch words details
    const words = await Word.find({ _id: { $in: wordIds } });
    if (words.length === 0) {
      return errorResponse(res, 'No valid words found for the provided IDs', 404);
    }

    const wordNames = words.map(w => w.word.toUpperCase());

    let storyData;
    const apiKey = process.env.GEMINI_API_KEY;

    // Helper: try to extract JSON object from model text (handles code fences or extra text)
    const parseJsonFromText = (text) => {
      if (!text || typeof text !== 'string') return null;
      // Remove triple backticks and surrounding whitespace
      const cleaned = text.replace(/```json\s*/i, '').replace(/```/g, '').trim();
      // Find first { and last }
      const first = cleaned.indexOf('{');
      const last = cleaned.lastIndexOf('}');
      const candidate = first !== -1 && last !== -1 ? cleaned.slice(first, last + 1) : cleaned;
      try {
        return JSON.parse(candidate);
      } catch (e) {
        return null;
      }
    };

    if (!apiKey || apiKey === 'your_gemini_api_key_here') {
      console.warn('⚠️ [Story Controller] GEMINI_API_KEY is not configured or invalid. Using fallback story generator.');
      storyData = generateFallbackStory(words);
    } else {
      try {
        const prompt = buildStoryPrompt(words, false);

        const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
        const payload = {
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { responseMimeType: 'application/json' }
        };

        console.log('ℹ️ [Story Controller] Calling Gemini API with enhanced prompt...');
        const resp = await axios.post(url, { 
          ...payload,
          generationConfig: {
            responseMimeType: 'application/json',
            temperature: 0.8,  // Higher temperature for diversity
            topP: 0.95,
            topK: 64
          }
        }, { headers: { 'Content-Type': 'application/json' }, timeout: 25000 });
        const jsonRes = resp.data;
        console.log('ℹ️ [Story Controller] Gemini response keys:', Object.keys(jsonRes || {}));
        const responseText = jsonRes.candidates?.[0]?.content?.parts?.[0]?.text;
        if (!responseText) throw new Error('Empty response from Gemini API');
        // Try robust parsing: model might wrap JSON in text or code fences
        const parsed = parseJsonFromText(responseText.trim());
        if (parsed) {
          storyData = parsed;
        } else {
          // Last resort: raw JSON.parse and let it fail to be caught
          try {
            storyData = JSON.parse(responseText.trim());
          } catch (e) {
            throw new Error('Failed to parse JSON from Gemini response');
          }
        }

        // Check for vocabulary list pattern in the generated story
        const wordNamesLower = words.map(w => w.word.toLowerCase());
        if (hasVocabListPattern(storyData.story, wordNamesLower)) {
          console.log('⚠️ [Story Controller] List pattern detected in story. Retrying with reinforced prompt...');
          try {
            const reinforcedPrompt = buildStoryPrompt(words, true);
            const retryPayload = {
              contents: [{ parts: [{ text: reinforcedPrompt }] }],
              generationConfig: { responseMimeType: 'application/json' }
            };

            console.log('ℹ️ [Story Controller] Retrying Gemini with reinforced prompt...');
            const retryResp = await axios.post(url, retryPayload, { headers: { 'Content-Type': 'application/json' }, timeout: 20000 });
            const retryJsonRes = retryResp.data;
            console.log('ℹ️ [Story Controller] Gemini retry response keys:', Object.keys(retryJsonRes || {}));
            const retryText = retryJsonRes.candidates?.[0]?.content?.parts?.[0]?.text;
            if (!retryText) throw new Error('Empty response from Gemini API on retry');
            const retryParsed = parseJsonFromText(retryText.trim());
            const retryStoryData = retryParsed || (function(){ try { return JSON.parse(retryText.trim()); } catch(e){ return null; } })();
            if (!retryStoryData) throw new Error('Failed to parse JSON from Gemini retry response');

            // If retry still has list pattern, fall back to static generator
            if (hasVocabListPattern(retryStoryData.story, wordNamesLower)) {
              console.log('⚠️ [Story Controller] List pattern still detected after retry. Using fallback story.');
              storyData = generateFallbackStory(words);
            } else {
              storyData = retryStoryData;
            }
          } catch (retryError) {
            console.error('❌ [Story Controller] Retry failed:', retryError.message);
            console.log('⚠️ Falling back to static story generation after retry failure...');
            storyData = generateFallbackStory(words);
          }
        }
      } catch (geminiError) {
        console.error('❌ [Story Controller] Gemini API invocation failed:', geminiError.message);
        console.log('⚠️ Falling back to static story generation...');
        storyData = generateFallbackStory(words);
      }
    }

    // 2. Save generated story in DB
    const newStory = await Story.create({
      user: req.user._id,
      title: storyData.title || 'An English Adventure',
      content: storyData.story,
      words: words.map(w => w._id),
      quiz: storyData.quiz,
      isCompleted: false,
      xpEarned: 0
    });

    // Populate words when returning
    const populatedStory = await Story.findById(newStory._id).populate('words');

    return successResponse(res, populatedStory, 'Story generated successfully! ✨', 201);
  } catch (err) {
    console.error('❌ [Story/generate]', err);
    return errorResponse(res, 'Server error during story generation', 500);
  }
};

/**
 * GET /api/stories
 * Retrieve all stories generated by the current user
 */
exports.getStories = async (req, res) => {
  try {
    const stories = await Story.find({ user: req.user._id })
      .populate('words')
      .sort({ createdAt: -1 });

    return successResponse(res, stories, 'Stories retrieved successfully');
  } catch (err) {
    console.error('❌ [Story/list]', err);
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * GET /api/stories/:id
 * Retrieve a specific story by ID
 */
exports.getStoryById = async (req, res) => {
  try {
    const story = await Story.findOne({ _id: req.params.id, user: req.user._id }).populate('words');
    if (!story) {
      return errorResponse(res, 'Story not found', 404);
    }
    return successResponse(res, story, 'Story retrieved successfully');
  } catch (err) {
    console.error('❌ [Story/getById]', err);
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * DELETE /api/stories/:id
 * Delete a story by ID — only the owner can delete their own story
 */
exports.deleteStory = async (req, res) => {
  try {
    // 1. Find story by _id AND user (ownership check)
    const story = await Story.findOne({ _id: req.params.id, user: req.user._id });

    // 2. If not found (doesn't exist or belongs to another user) → 404
    if (!story) {
      return errorResponse(res, 'Story not found', 404);
    }

    // 3. Delete the story → 200
    await story.deleteOne();
    return successResponse(res, null, 'Story deleted successfully');
  } catch (err) {
    console.error('❌ [Story/delete]', err);
    return errorResponse(res, 'Server error', 500);
  }
};

/**
 * POST /api/stories/:id/complete
 * Mark quiz as completed and award +30 XP bonus to the user
 */
exports.completeStoryQuiz = async (req, res) => {
  try {
    const story = await Story.findOne({ _id: req.params.id, user: req.user._id });
    if (!story) {
      return errorResponse(res, 'Story not found', 404);
    }

    if (story.isCompleted) {
      return successResponse(res, { story, xpAwarded: 0 }, 'Story was already completed');
    }

    // Award +30 XP bonus
    const xpBonus = 30;
    story.isCompleted = true;
    story.xpEarned = xpBonus;
    await story.save();

    const user = await User.findById(req.user._id);
    if (user) {
      user.totalXP += xpBonus;
      user.dailyXP += xpBonus;
      await user.save();
    }

    return successResponse(res, { story, xpAwarded: xpBonus }, 'Story quiz completed! +30 XP Awarded 🎉');
  } catch (err) {
    console.error('❌ [Story/complete]', err);
    return errorResponse(res, 'Server error during completion', 500);
  }
};
