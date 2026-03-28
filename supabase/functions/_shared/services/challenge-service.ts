import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

type CreateChallengeInput = {
  title: string;
  description?: string;
  difficulty?: "easy" | "medium" | "hard";
  techStack?: string;
  pointsReward?: number;
};

type CompleteChallengeInput = {
  submissionText?: string;
  submissionLink?: string;
};

export class ChallengeService {
  constructor(private readonly client: SupabaseClient) {}

  async listChallenges() {
    const { data, error } = await this.client
      .from("challenges")
      .select(
        "id, title, description, difficulty, tech_stack, points_reward, is_active, created_at",
      )
      .eq("is_active", true)
      .order("created_at", { ascending: false });

    if (error) throw error;
    return data;
  }

  async createChallenge(input: CreateChallengeInput) {
    if (!input.title.trim()) {
      throw new Error("Challenge title is required");
    }

    const difficulty = ["easy", "medium", "hard"].includes(input.difficulty ?? "")
      ? input.difficulty
      : "easy";

    const { data, error } = await this.client
      .from("challenges")
      .insert({
        title: input.title.trim(),
        description: input.description?.trim() ?? "",
        difficulty,
        tech_stack: input.techStack?.trim() || "General",
        points_reward: Math.max(0, Number(input.pointsReward ?? 20)),
      })
      .select(
        "id, title, description, difficulty, tech_stack, points_reward, is_active, created_at",
      )
      .single();

    if (error) throw error;
    return data;
  }

  async assignDailyChallenge(techStack?: string) {
    const { data: assignment, error: assignmentError } = await this.client.rpc(
      "assign_daily_challenge",
      {
        p_requested_stack: techStack?.trim() || null,
      },
    );

    if (assignmentError) throw assignmentError;

    const challengeId = assignment.challenge_id as string;
    const { data: challenge, error: challengeError } = await this.client
      .from("challenges")
      .select("id, title, description, difficulty, tech_stack, points_reward")
      .eq("id", challengeId)
      .single();

    if (challengeError) throw challengeError;

    return {
      ...assignment,
      challenge,
    };
  }

  async completeDailyChallenge(input: CompleteChallengeInput) {
    const { data, error } = await this.client.rpc("complete_daily_challenge", {
      p_submission_text: input.submissionText?.trim() ?? "",
      p_submission_link: input.submissionLink?.trim() ?? "",
    });

    if (error) throw error;
    return data;
  }

  async getTodayAssignment() {
    const { data, error } = await this.client
      .from("user_challenges")
      .select(
        "id, challenge_id, assigned_date, selected_tech_stack, completed, completed_at, submission_text, submission_link",
      )
      .order("assigned_date", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) throw error;
    return data;
  }
}
