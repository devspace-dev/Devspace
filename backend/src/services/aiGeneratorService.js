import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from 'dotenv';
dotenv.config();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

/**
 * Generates a coding challenge based on a tech stack and difficulty.
 * @param {string} techStack - e.g., 'Flutter', 'React', 'Node.js'
 * @param {string} type - 'daily' or 'weekly'
 */
export const generateAIChallenge = async (techStack = 'General', type = 'daily') => {
  const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

  const prompt = `
    Generate a ${type} coding challenge for a student learning ${techStack}.
    The challenge should be practical and encourage deep learning.
    
    Return the response in STRICT JSON format with these fields:
    - title: A short, catchy title.
    - description: A detailed explanation of the task (Markdown supported).
    - difficulty: 'Easy', 'Medium', or 'Hard'.
    - points_reward: An integer between 10 and 100.
    
    Example for Daily Flutter:
    {
      "title": "Custom Painter Progress Bar",
      "description": "Create a circular progress bar using CustomPainter that animates when the value changes.",
      "difficulty": "Medium",
      "points_reward": 30
    }
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    
    // Extract JSON if AI wraps it in code blocks
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }
    return JSON.parse(text);
  } catch (error) {
    console.error("AI Generation Error:", error);
    throw new Error("Failed to generate AI challenge content.");
  }
};

/**
 * Generates a personalized weekly coding challenge based on User Profile and Tier.
 * @param {Object} userProfile - { name, careerGoal, skillLevel, techStack, tier }
 */
export const generatePersonalizedWeeklyChallenge = async (userProfile) => {
  const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

  const prompt = `
You are an expert coding challenge designer for DevSpace, a developer social platform for students and early-career developers.

Your job is to generate ONE weekly coding challenge based on the user's profile and challenge tier.

---

[USER PROFILE]
- Name: ${userProfile.name}
- Career Goal / Specialisation: ${userProfile.careerGoal}  (e.g. "Flutter Developer", "ML Engineer", "Backend with Node.js", "DevOps")
- Current Skill Level: ${userProfile.skillLevel}  (Beginner / Intermediate / Advanced)
- Tech Stack: ${userProfile.techStack}  (e.g. "Flutter, Dart, Supabase")
- Tier: ${userProfile.tier}  (FREE or PAID)

---

[GENERATION RULES]

If Tier = FREE:
- Generate a general software engineering or CS fundamentals challenge
- Topics: arrays, strings, recursion, basic data structures, REST API usage, simple SQL
- No career-path personalisation
- Difficulty: based on skill level

If Tier = PAID:
- Generate a challenge that is DIRECTLY aligned with the user's career goal and tech stack
- It should simulate a real-world problem they'd encounter in their target role
- Include: a career context framing (e.g. "As a Flutter developer at a startup, you need to...")
- The problem should reinforce skill growth in their specialisation
- Optionally include a "Why this matters for your career" section

---

[OUTPUT FORMAT — respond in strict JSON, no extra text]

{
  "title": "Challenge title here",
  "tier": "FREE or PAID",
  "difficulty": "Easy / Medium / Hard",
  "career_context": "Only for PAID tier — 1-2 lines explaining real-world relevance. Empty string for FREE.",
  "problem_statement": "Full problem description here",
  "constraints": ["constraint 1", "constraint 2"],
  "sample_input": "example input",
  "sample_output": "example output",
  "hint": "Optional subtle hint",
  "why_this_matters": "Only for PAID tier — how this builds toward their career goal. Empty string for FREE.",
  "tags": ["tag1", "tag2", "tag3"],
  "xp_reward": 100
}
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    
    // Extract JSON if AI wraps it in code blocks
    const jsonMatch = text.match(/\\{[\\s\\S]*\\}/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }
    return JSON.parse(text);
  } catch (error) {
    console.error("AI Generation Error:", error);
    throw new Error("Failed to generate personalized AI challenge.");
  }
};
