import express from "express";
import cors from "cors";
import injuryRoutes from "./routes/injury.js";

const app = express();
app.use(cors());
app.use(express.json());

app.use("/injuries/upload-id-photo", injuryRoutes);

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
