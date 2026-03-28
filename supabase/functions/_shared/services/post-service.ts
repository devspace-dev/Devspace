import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

type CreatePostInput = {
  content: string;
  tags?: string[];
  imageUrl?: string;
  quotePostId?: string | null;
};

type AddCommentInput = {
  postId: string;
  content: string;
};

export class PostService {
  constructor(private readonly client: SupabaseClient) {}

  async listPosts(limit: number, offset: number) {
    const from = Math.max(0, offset);
    const to = from + Math.max(1, Math.min(limit, 50)) - 1;

    const { data, error } = await this.client
      .from("posts")
      .select(
        "id, user_id, content, tags, image_url, quote_post_id, likes_count, comments_count, reposts_count, created_at",
      )
      .order("created_at", { ascending: false })
      .range(from, to);

    if (error) throw error;
    return data;
  }

  async createPost(input: CreatePostInput) {
    const { data, error } = await this.client.rpc("create_post_with_aura", {
      p_content: input.content,
      p_tags: input.tags ?? [],
      p_image_url: input.imageUrl ?? "",
      p_quote_post_id: input.quotePostId ?? null,
    });

    if (error) throw error;
    return { id: data };
  }

  async likePost(postId: string) {
    const { data, error } = await this.client.rpc("like_post_with_aura", {
      p_post_id: postId,
    });

    if (error) throw error;
    return data;
  }

  async unlikePost(postId: string) {
    const { data, error } = await this.client.rpc("unlike_post", {
      p_post_id: postId,
    });

    if (error) throw error;
    return data;
  }

  async addComment(input: AddCommentInput) {
    const { data, error } = await this.client.rpc("add_comment_with_aura", {
      p_post_id: input.postId,
      p_content: input.content,
    });

    if (error) throw error;
    return { id: data };
  }
}
