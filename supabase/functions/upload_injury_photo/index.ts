import { serve } from "https://deno.land/std@0.201.0/http/server.ts";
import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(supabaseUrl, supabaseKey);

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
      });
    }

    const formData = await req.formData();
    const file = formData.get("file") as File;
    const injuryId = formData.get("injuryId") as string;

    if (!file || !injuryId) {
      return new Response(
        JSON.stringify({ error: "Missing file or injuryId" }),
        {
          status: 400,
        }
      );
    }

    const fileBytes = new Uint8Array(await file.arrayBuffer());
    const path = `${injuryId}/id_photo.jpg`;

    const { error } = await supabase.storage
      .from("injury-files")
      .upload(path, fileBytes, { upsert: true, contentType: file.type });

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
      });
    }

    const publicUrl = supabase.storage.from("injury-files").getPublicUrl(path)
      .data.publicUrl;

    return new Response(
      JSON.stringify({ success: true, injuryId, filePath: publicUrl }),
      { status: 200 }
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
    });
  }
});
