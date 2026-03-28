import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

type MissionType = "coding" | "mcq" | "oneword";

type CreateMissionInput = {
  title: string;
  type: MissionType;
  techStack?: string;
  question: string;
  options?: unknown[];
  correctAnswer?: string;
  link?: string;
  pointsReward?: number;
  publishDate?: string;
  isActive?: boolean;
};

type UpdateMissionInput = Partial<CreateMissionInput>;

type SubmitMissionInput = {
  answerSubmitted?: string;
  submissionLink?: string;
};

type ReviewMissionInput = {
  isCorrect: boolean;
};

export class MissionService {
  constructor(private readonly client: SupabaseClient) {}

  async listMissions(includeInactive = false) {
    let query = this.client
      .from("missions")
      .select(
        "id, title, type, tech_stack, question, options, correct_answer, link, points_reward, publish_date, is_active, created_at, updated_at",
      )
      .order("publish_date", { ascending: false })
      .order("created_at", { ascending: false });

    if (!includeInactive) {
      query = query.eq("is_active", true);
    }

    const { data, error } = await query;

    if (error) throw error;
    return data;
  }

  async createMission(input: CreateMissionInput) {
    this.validateMissionPayload(input);

    const { data, error } = await this.client
      .from("missions")
      .insert({
        title: input.title.trim(),
        type: input.type,
        tech_stack: this.normalizeStack(input.techStack),
        question: input.question.trim(),
        options: input.type === "mcq" ? input.options ?? [] : null,
        correct_answer: this.normalizeNullableText(input.correctAnswer),
        link: this.normalizeNullableText(input.link),
        points_reward: this.normalizePoints(input.pointsReward),
        publish_date: input.publishDate,
        is_active: input.isActive ?? true,
      })
      .select(
        "id, title, type, tech_stack, question, options, correct_answer, link, points_reward, publish_date, is_active, created_at, updated_at",
      )
      .single();

    if (error) throw error;
    return data;
  }

  async updateMission(missionId: string, input: UpdateMissionInput) {
    if (!missionId.trim()) {
      throw new Error("Mission ID is required");
    }

    const { data: existingMission, error: existingError } = await this.client
      .from("missions")
      .select(
        "id, title, type, tech_stack, question, options, correct_answer, link, points_reward, publish_date, is_active",
      )
      .eq("id", missionId)
      .single();

    if (existingError) throw existingError;

    const mergedInput: CreateMissionInput = {
      title: input.title ?? existingMission.title,
      type: (input.type ?? existingMission.type) as MissionType,
      techStack: input.techStack ?? existingMission.tech_stack,
      question: input.question ?? existingMission.question,
      options: input.options ?? existingMission.options ?? undefined,
      correctAnswer: input.correctAnswer ?? existingMission.correct_answer ?? undefined,
      link: input.link ?? existingMission.link ?? undefined,
      pointsReward: input.pointsReward ?? existingMission.points_reward,
      publishDate: input.publishDate ?? existingMission.publish_date,
      isActive: input.isActive ?? existingMission.is_active,
    };

    this.validateMissionPayload(mergedInput);

    const updatePayload: Record<string, unknown> = {
      title: mergedInput.title.trim(),
      type: mergedInput.type,
      tech_stack: this.normalizeStack(mergedInput.techStack),
      question: mergedInput.question.trim(),
      options: mergedInput.type === "mcq" ? mergedInput.options ?? [] : null,
      correct_answer: this.normalizeNullableText(mergedInput.correctAnswer),
      link: this.normalizeNullableText(mergedInput.link),
      points_reward: this.normalizePoints(mergedInput.pointsReward),
      publish_date: mergedInput.publishDate,
      is_active: mergedInput.isActive ?? true,
      updated_at: new Date().toISOString(),
    };

    const { data, error } = await this.client
      .from("missions")
      .update(updatePayload)
      .eq("id", missionId)
      .select(
        "id, title, type, tech_stack, question, options, correct_answer, link, points_reward, publish_date, is_active, created_at, updated_at",
      )
      .single();

    if (error) throw error;
    return data;
  }

  async assignDailyMission(techStack?: string) {
    const { data: assignment, error: assignmentError } = await this.client.rpc(
      "assign_daily_mission",
      {
        p_requested_stack: this.normalizeNullableText(techStack),
      },
    );

    if (assignmentError) throw assignmentError;
    return await this.getAssignmentWithMission(assignment.id as string);
  }

  async getTodayAssignment() {
    const todayUtc = new Date().toISOString().slice(0, 10);
    const { data, error } = await this.client
      .from("user_missions")
      .select("id")
      .eq("assigned_date", todayUtc)
      .order("assigned_date", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) throw error;
    if (!data?.id) return null;

    return await this.getAssignmentWithMission(data.id);
  }

  async submitDailyMission(input: SubmitMissionInput) {
    const { data, error } = await this.client.rpc("submit_daily_mission", {
      p_answer_submitted: input.answerSubmitted?.trim() ?? "",
      p_submission_link: input.submissionLink?.trim() ?? "",
    });

    if (error) throw error;
    return data;
  }

  async reviewMissionAssignment(assignmentId: string, input: ReviewMissionInput) {
    if (!assignmentId.trim()) {
      throw new Error("Assignment ID is required");
    }

    const { data, error } = await this.client.rpc("review_daily_mission", {
      p_assignment_id: assignmentId,
      p_is_correct: input.isCorrect,
    });

    if (error) throw error;
    return data;
  }

  private async getAssignmentWithMission(assignmentId: string) {
    const { data, error } = await this.client
      .from("user_missions")
      .select(`
        id,
        user_id,
        mission_id,
        assigned_date,
        selected_tech_stack,
        completed,
        answer_submitted,
        submission_link,
        is_correct,
        completed_at,
        reviewed_by,
        reviewed_at,
        created_at,
        updated_at,
        mission:missions (
          id,
          title,
          type,
          tech_stack,
          question,
          options,
          correct_answer,
          link,
          points_reward,
          publish_date,
          is_active
        )
      `)
      .eq("id", assignmentId)
      .single();

    if (error) throw error;
    return data;
  }

  private validateMissionPayload(input: CreateMissionInput) {
    if (!input.title?.trim()) {
      throw new Error("Mission title is required");
    }

    if (!["coding", "mcq", "oneword"].includes(input.type)) {
      throw new Error("Mission type must be coding, mcq, or oneword");
    }

    if (!input.question?.trim()) {
      throw new Error("Mission question is required");
    }

    if (!input.publishDate?.trim()) {
      throw new Error("Publish date is required");
    }

    if (input.type === "coding" && !input.link?.trim()) {
      throw new Error("Coding missions require a link");
    }

    if (input.type === "mcq") {
      if (!Array.isArray(input.options) || input.options.length < 2) {
        throw new Error("MCQ missions require at least two options");
      }

      if (!input.correctAnswer?.trim()) {
        throw new Error("MCQ missions require a correct answer");
      }

      const normalizedOptions = input.options.map((option) =>
        String(option).trim().toLowerCase()
      );
      if (!normalizedOptions.includes(input.correctAnswer.trim().toLowerCase())) {
        throw new Error("MCQ correct answer must match one of the provided options");
      }
    }

    if (input.type === "oneword" && !input.correctAnswer?.trim()) {
      throw new Error("One-word missions require a correct answer");
    }
  }

  private normalizeStack(stack?: string) {
    return stack?.trim() || "general";
  }

  private normalizeNullableText(value?: string | null) {
    const trimmed = value?.trim() ?? "";
    return trimmed.length > 0 ? trimmed : null;
  }

  private normalizePoints(points?: number) {
    return Math.max(0, Number(points ?? 20));
  }
}
