
const express = require("express");

const app = express();
app.disable("x-powered-by");

// Replace these examples with real, authorized audio URLs.
// Metadata must match the actual audio, not the desired quality.
const tracks = [
  {
    id: "stereo-demo",
    title: "Your Stereo Track",
    artist: "Your Artist",
    album: "Your Album",
    duration: 240,
    mode: "stereo",
    url: "https://YOUR-HOST/your-track.flac",
    format: "flac",
    codec: "flac",
    container: "flac",
    manifest: "none",
    encrypted: false,
    sampleRate: 44100,
    bitDepth: 16
  },
  {
    id: "atmos-demo",
    title: "Your Atmos Track",
    artist: "Your Artist",
    album: "Your Album",
    duration: 240,
    mode: "atmos",
    url: "https://YOUR-HOST/your-atmos-manifest.mpd",
    format: "dash",
    codec: "eac3-joc",
    container: "mp4",
    manifest: "dash",
    encrypted: false,
    sampleRate: 48000
  }
];

app.get("/manifest.json", (req, res) => {
  res.json({
    id: "dev.light.lossless",
    name: "Light Lossless + Atmos",
    version: "1.0.0",
    resources: ["search", "stream"],
    allowDownloads: 0,
    checkValidLossless: 0
  });
});

app.get("/search", (req, res) => {
  const q = String(req.query.q || "").toLowerCase();
  const quality = String(req.query.quality || "high").toLowerCase();
  const atmos = req.query.atmos === "auto";

  let results = tracks.filter(t =>
    [t.title, t.artist, t.album]
      .join(" ").toLowerCase().includes(q)
  );

  // For a lossless-only request, never claim a lossy
  // Atmos stream is lossless.
  if (quality === "lossless") {
    results = results.filter(t => t.codec === "flac");
  }

  if (atmos) {
    results.sort((a, b) =>
      Number(b.mode === "atmos") - Number(a.mode === "atmos")
    );
  }

  res.set("Cache-Control", "no-store");
  res.json({
    tracks: results.map(t => ({
      id: t.id,
      title: t.title,
      artist: t.artist,
      album: t.album,
      duration: t.duration,
      format: t.format,
      audioQuality: t.codec === "flac" ? "LOSSLESS" : "HIGH",
      ...(t.mode === "atmos"
        ? { atmos: true, audioModes: ["DOLBY_ATMOS"] }
        : {})
    }))
  });
});

app.get("/stream/:id", (req, res) => {
  const track = tracks.find(t => t.id === req.params.id);

  if (!track) return res.status(404).end();

  const quality = String(req.query.quality || "high").toLowerCase();
  const atmos = req.query.atmos === "auto";

  // Never label lossy audio as lossless.
  if (quality === "lossless" && track.codec !== "flac") {
    return res.status(404).end();
  }

  if (track.mode === "atmos" && !atmos) {
    return res.status(404).end();
  }

  res.set("Cache-Control", "no-store");
  res.json({
    url: track.url,
    format: track.format,
    quality: track.codec === "flac" ? "Lossless" : "Dolby Atmos",
    codec: track.codec,
    container: track.container,
    manifest: track.manifest,
    encrypted: track.encrypted,
    sampleRate: track.sampleRate,
    ...(track.bitDepth ? { bitDepth: track.bitDepth } : {}),
    ...(track.mode === "atmos"
      ? { audioMode: "DOLBY_ATMOS" }
      : {})
  });
});

app.get("/", (req, res) => {
  res.type("text").send("Light addon server is running.");
});

const port = process.env.PORT || 3000;
app.listen(port, "0.0.0.0", () =>
  console.log(`Addon listening on ${port}`)
);
    
