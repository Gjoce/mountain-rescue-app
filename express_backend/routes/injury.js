import express from "express";
import multer from "multer";
import { supabase } from "../supabase.js";

const router = express.Router();

const upload = multer({ storage: multer.memoryStorage() });

router.post("/", upload.single("file"), async (req, res) => {
  try {
    const { userId } = req.body;
    const file = req.file;

    if (!file) return res.status(400).json({ error: "No file provided" });
    if (!userId) return res.status(400).json({ error: "Missing userId" });

    const injuryId = crypto.randomUUID();

    const path = `${injuryId}/id_photo.jpg`;

    const { error } = await supabase.storage
      .from(process.env.BUCKET_NAME)
      .upload(path, file.buffer, {
        contentType: file.mimetype,
        upsert: true,
      });

    if (error) {
      console.error("Upload Error:", error);
      return res.status(500).json({ error: error.message });
    }

    return res.json({
      success: true,
      injuryId,
      filePath: path,
      message: "Injury registered & file uploaded",
    });
  } catch (err) {
    console.error("Error:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

export default router;
