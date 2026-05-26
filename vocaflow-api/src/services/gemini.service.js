/**
 * Gemini AI Service for LingoPro
 * Handles communication with Google Generative AI (Gemini API)
 */

const { GoogleGenerativeAI } = require('@google/generative-ai');

// Check if Gemini API key exists
const apiKey = process.env.GEMINI_API_KEY;
let genAI = null;

if (apiKey) {
  genAI = new GoogleGenerativeAI(apiKey);
} else {
  console.warn('[WARNING] GEMINI_API_KEY is not defined in environment variables. AI features will fallback to dummy content.');
}

/**
 * Helper to safely extract JSON from AI response, stripping markdown fences if present
 */
const parseJsonFromText = (text) => {
  if (!text || typeof text !== 'string') return null;
  const cleaned = text.replace(/```json\s*/i, '').replace(/```/g, '').trim();
  const first = cleaned.indexOf('{');
  const last = cleaned.lastIndexOf('}');
  const candidate = first !== -1 && last !== -1 ? cleaned.slice(first, last + 1) : cleaned;
  try {
    return JSON.parse(candidate);
  } catch (e) {
    return null;
  }
};

/**
 * Generates an English story and Vietnamese translation based on a list of words.
 * @param {Array<Object>} words - List of word objects containing { word, meaningVn, definitionEn, partOfSpeech }
 * @returns {Promise<Object>} Object containing { storyEn, storyVi }
 */
exports.generateStoryFromWords = async (words) => {
  try {
    if (!genAI) {
      return getDummyStory(words);
    }

    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });

    // Format list of words for prompt
    const wordListStr = words.map(w => `- ${w.word} (${w.partOfSpeech}): nghĩa tiếng Việt: ${w.meaning_vn || w.meaningVn}, định nghĩa tiếng Anh: ${w.definition_en || w.definitionEn}`).join('\n');

    const prompt = `
Bạn là một giáo viên tiếng Anh bản xứ tài năng và thân thiện.
Tôi sẽ cung cấp cho bạn một danh sách các từ vựng mà học sinh vừa mới học xong.
Nhiệm vụ của bạn là viết một mẩu chuyện ngắn hoặc một đoạn hội thoại thực tế, hài hước, sinh động bằng tiếng Anh (khoảng 100-150 từ) chứa ĐẦY ĐỦ các từ vựng đó.

DANH SÁCH TỪ VỰNG:
${wordListStr}

YÊU CẦU:
1. Viết một câu chuyện/hội thoại tiếng Anh mạch lạc, ngữ pháp chuẩn xác và tự nhiên.
2. BẮT BUỘC bọc các từ vựng trong danh sách trên bằng thẻ <b> từ </b> trong câu chuyện tiếng Anh (Ví dụ: <b>vibrant</b>, <b>ubiquitous</b>). Thẻ này giúp ứng dụng của tôi hiển thị bôi đậm cho học sinh. Hãy linh hoạt chia thì hoặc chuyển đổi số nhiều nếu cần, nhưng vẫn bọc từ trong thẻ <b>.
3. Cung cấp một bản dịch nghĩa tiếng Việt đầy đủ, mượt mà và tự nhiên cho câu chuyện/hội thoại này.
4. Trả về kết quả CHỈ ở định dạng JSON thô (Raw JSON), không bọc trong khối code markdown \`\`\`json ... \`\`\`. Định dạng JSON phải chính xác như sau:
{
  "storyEn": "Nội dung câu chuyện tiếng Anh chứa các từ đã học bọc trong thẻ <b>...",
  "storyVi": "Bản dịch nghĩa tiếng Việt tương ứng..."
}
`;

    const result = await model.generateContent({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: {
        responseMimeType: 'application/json',
      }
    });

    const responseText = result.response.text();
    const data = parseJsonFromText(responseText.trim());
    if (!data) throw new Error('Failed to parse JSON from Gemini story response');

    return {
      storyEn: data.storyEn,
      storyVi: data.storyVi,
    };

  } catch (error) {
    console.error('❌ [Gemini Service Error]:', error.message);
    return getDummyStory(words); // fallback
  }
};

/**
 * Fallback generator when Gemini API fails or is not configured
 */
function getDummyStory(words) {
  const wordSpans = words.map(w => `<b>${w.word}</b>`).join(', ');
  const wordMeanings = words.map(w => `${w.word} (${w.meaning_vn || w.meaningVn})`).join(', ');

  return {
    storyEn: `Once upon a time, a diligent student wanted to improve their English. Every day, they practiced vocabulary. Today, they learned several useful expressions including: ${wordSpans}. By learning these words, they became much more confident in expressing themselves in any situation. Remember, practice makes perfect, and keeping a daily learning habit is the key to mastering any language!`,
    storyVi: `Ngày xửa ngày xưa, có một học sinh chăm chỉ muốn cải thiện tiếng Anh của mình. Mỗi ngày, họ đều luyện tập từ vựng. Hôm nay, họ đã học được một số cụm từ hữu ích bao gồm: ${wordMeanings}. Bằng cách học những từ này, họ đã trở nên tự tin hơn nhiều trong việc thể hiện bản thân trong mọi tình huống. Hãy nhớ rằng, có công mài sắt có ngày nên kim, và duy trì thói quen học tập hàng ngày là chìa khóa để làm chủ bất kỳ ngôn ngữ nào!`
  };
}

/**
 * Generates an English vocabulary deck related to a topic and CEFR level.
 * @param {string} topic - Topic of the vocabulary deck (e.g. "Space exploration")
 * @param {string} [level] - CEFR level (A1, A2, B1, B2, C1, C2)
 * @returns {Promise<Array<Object>>} List of generated words
 */
exports.generateAIDeck = async (topic, level = 'B2') => {
  try {
    if (!genAI) {
      return getDummyDeck(topic, level);
    }

    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });

    const prompt = `
You are an expert English language teacher and lexicographer.
Generate EXACTLY 8 high-quality English vocabulary words related to the topic: "${topic}".
The vocabulary words should be suitable for the CEFR level: "${level}".

For each word, generate a complete learning card in the exact JSON format below. Do not include markdown code block formatting (like \`\`\`json). Just return raw JSON. Make sure Vietnamese meanings are natural, definitions are accurate, and examples are highly contextual and clear.

Format:
{
  "words": [
    {
      "word": "word in lowercase",
      "meaning_vn": "natural Vietnamese meaning",
      "definition_vn": "clear Vietnamese definition",
      "definition_en": "accurate English definition",
      "example": "an illustrative English example sentence containing this word in a natural context",
      "example_vn": "accurate and natural Vietnamese translation of the example sentence",
      "pronunciation": "IPA phonetic transcription (without slashes / / or brackets [ ], e.g. əˈbɪl.ə.ti)",
      "partOfSpeech": "noun/verb/adjective/adverb/preposition/conjunction/pronoun",
      "difficulty": 3,
      "tags": ["tag1", "tag2"],
      "synonyms": ["synonym1"],
      "antonyms": ["antonym1"]
    }
  ]
}
`;

    const result = await model.generateContent({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: {
        responseMimeType: 'application/json',
      }
    });

    const responseText = result.response.text();
    const data = parseJsonFromText(responseText.trim());

    if (data && Array.isArray(data.words)) {
      return data.words.map(w => ({
        ...w,
        level: w.level || level
      }));
    }
    return getDummyDeck(topic, level);

  } catch (error) {
    console.error('❌ [Gemini generateAIDeck Error]:', error.message);
    return getDummyDeck(topic, level);
  }
};

/**
 * Fallback generator when Gemini API fails or is not configured
 */
function getDummyDeck(topic, level) {
  const cleanTopic = topic.toLowerCase();
  
  // Custom dummy words for common topics or fallback
  const dummyWords = [
    {
      word: "innovation",
      meaning_vn: "sự đổi mới, sáng kiến",
      definition_vn: "Giới thiệu ý tưởng mới hoặc phương pháp mới.",
      definition_en: "The introduction of something new, such as an idea, method, or device.",
      example: "Technical innovation is key to the growth of this company.",
      example_vn: "Đổi mới công nghệ là chìa khóa cho sự phát triển của công ty này.",
      pronunciation: "ˌɪn.əˈveɪ.ʃən",
      partOfSpeech: "noun",
      difficulty: 3,
      tags: ["tech", "business"],
      synonyms: ["novelty", "creation"],
      antonyms: ["stagnation"]
    },
    {
      word: "sustainability",
      meaning_vn: "sự bền vững",
      definition_vn: "Khả năng được duy trì ở một mức độ hoặc tốc độ nhất định.",
      definition_en: "The quality of being able to continue over a period of time.",
      example: "The government has created a new committee on environmental sustainability.",
      example_vn: "Chính phủ đã thành lập một ủy ban mới về sự bền vững môi trường.",
      pronunciation: "səˌsteɪ.nəˈbɪl.ə.ti",
      partOfSpeech: "noun",
      difficulty: 4,
      tags: ["environment", "future"],
      synonyms: ["viability"],
      antonyms: ["instability"]
    },
    {
      word: "acquire",
      meaning_vn: "thu được, đạt được",
      definition_vn: "Có được thứ gì đó hoặc đạt được kiến thức, kỹ năng.",
      definition_en: "To obtain something, or to learn or develop a skill or habit.",
      example: "It takes time to acquire a new language naturally.",
      example_vn: "Cần có thời gian để đạt được một ngôn ngữ mới một cách tự nhiên.",
      pronunciation: "əˈkwaɪər",
      partOfSpeech: "verb",
      difficulty: 2,
      tags: ["learning", "development"],
      synonyms: ["obtain", "gain"],
      antonyms: ["lose", "forfeit"]
    },
    {
      word: "collaborate",
      meaning_vn: "hợp tác, cộng tác",
      definition_vn: "Làm việc chung với ai đó để sản xuất hoặc đạt được thứ gì đó.",
      definition_en: "To work jointly on an activity or project, especially to produce or create something.",
      example: "Researchers from around the world collaborate on this study.",
      example_vn: "Các nhà nghiên cứu từ khắp nơi trên thế giới cộng tác trong nghiên cứu này.",
      pronunciation: "kəˈlæb.ə.reɪt",
      partOfSpeech: "verb",
      difficulty: 3,
      tags: ["work", "teamwork"],
      synonyms: ["cooperate", "partner"],
      antonyms: ["compete"]
    },
    {
      word: "vibrant",
      meaning_vn: "sống động, đầy sức sống",
      definition_vn: "Đầy sinh lực, năng lượng và nhiệt huyết.",
      definition_en: "Full of energy, life, and enthusiasm.",
      example: "The city has a vibrant cultural life with many galleries and theaters.",
      example_vn: "Thành phố có đời sống văn hóa sống động với nhiều phòng triển lãm và nhà hát.",
      pronunciation: "ˈvaɪ.brənt",
      partOfSpeech: "adjective",
      difficulty: 3,
      tags: ["descriptive", "life"],
      synonyms: ["energetic", "lively"],
      antonyms: ["dull", "lifeless"]
    },
    {
      word: "resilient",
      meaning_vn: "kiên cường, đàn hồi",
      definition_vn: "Có khả năng phục hồi nhanh chóng từ những khó khăn.",
      definition_en: "Able to withstand or recover quickly from difficult conditions.",
      example: "Children are often remarkably resilient in times of stress.",
      example_vn: "Trẻ em thường kiên cường một cách đáng kinh ngạc trong những thời điểm căng thẳng.",
      pronunciation: "rɪˈzɪl.jənt",
      partOfSpeech: "adjective",
      difficulty: 4,
      tags: ["personality", "strength"],
      synonyms: ["tough", "strong"],
      antonyms: ["fragile", "vulnerable"]
    },
    {
      word: "advocate",
      meaning_vn: "ủng hộ, người ủng hộ",
      definition_vn: "Ủng hộ công khai một lý tưởng hoặc chính sách.",
      definition_en: "To publicly recommend or support a particular cause or policy.",
      example: "We advocate for sustainable energy practices worldwide.",
      example_vn: "Chúng tôi ủng hộ các hoạt động năng lượng bền vững trên toàn thế giới.",
      pronunciation: "ˈæd.və.keɪt",
      partOfSpeech: "verb",
      difficulty: 3,
      tags: ["support", "formal"],
      synonyms: ["support", "champion"],
      antonyms: ["oppose", "criticize"]
    },
    {
      word: "empirical",
      meaning_vn: "thực nghiệm, dựa trên thực tế",
      definition_vn: "Dựa trên hoặc kiểm chứng bằng thực tế quan sát, thay vì lý thuyết thuần túy.",
      definition_en: "Based on, concerned with, or verifiable by observation or experience rather than theory or pure logic.",
      example: "They provided strong empirical evidence to support their claims.",
      example_vn: "Họ đã cung cấp bằng chứng thực nghiệm mạnh mẽ để hỗ trợ các tuyên bố của mình.",
      pronunciation: "ɪmˈpɪr.ɪ.kəl",
      partOfSpeech: "adjective",
      difficulty: 5,
      tags: ["academic", "research"],
      synonyms: ["factual", "observational"],
      antonyms: ["theoretical", "speculative"]
    }
  ];

  return dummyWords.map(w => ({
    ...w,
    topic: topic,
    level: level
  }));
}
