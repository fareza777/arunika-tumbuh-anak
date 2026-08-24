import {
  AbsoluteFill,
  Composition,
  Easing,
  Folder,
  interpolate,
  Sequence,
  Still,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import type { ReactNode } from "react";

const palette = {
  ivory: "#FBF7EF",
  paper: "#FFFDF8",
  ink: "#35291F",
  muted: "#756B60",
  gold: "#C49A4A",
  goldSoft: "#F3DFAC",
  terracotta: "#B96652",
  terracottaSoft: "#F7E4DC",
  sage: "#4D6C58",
  sageSoft: "#E9F0E8",
  lavender: "#EEE9F1",
  line: "rgba(53, 41, 31, 0.12)",
};

type ScreenKind = "today" | "rituals" | "ritual-editor" | "moments" | "moment-editor" | "garden" | "scrapbook" | "privacy";

type SceneProps = {
  readonly durationInFrames: number;
  readonly children: ReactNode;
  readonly background?: string;
  readonly light?: boolean;
};

const ease = Easing.bezier(0.16, 1, 0.3, 1);

const appear = (frame: number, delay = 0, length = 20) =>
  interpolate(frame, [delay, delay + length], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: ease,
  });

const rise = (frame: number, delay = 0, distance = 44) =>
  interpolate(frame, [delay, delay + 22], [distance, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: ease,
  });

const Scene: React.FC<SceneProps> = ({ children, durationInFrames, background = palette.ivory, light = false }) => {
  const frame = useCurrentFrame();
  const fade = interpolate(frame, [0, 16, Math.max(16, durationInFrames - 16), durationInFrames], [0, 1, 1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: ease,
  });
  return (
    <AbsoluteFill style={{ background, color: light ? palette.paper : palette.ink, opacity: fade, overflow: "hidden" }}>
      <div style={{ backgroundImage: `linear-gradient(${light ? "rgba(255,255,255,.07)" : "rgba(53,41,31,.05)"} 1px, transparent 1px), linear-gradient(90deg, ${light ? "rgba(255,255,255,.07)" : "rgba(53,41,31,.05)"} 1px, transparent 1px)`, backgroundSize: "72px 72px", inset: 0, opacity: 0.7, position: "absolute" }} />
      {children}
    </AbsoluteFill>
  );
};

const Brand: React.FC<{ readonly light?: boolean; readonly small?: boolean }> = ({ light = false, small = false }) => (
  <div style={{ alignItems: "center", display: "flex", gap: small ? 12 : 18 }}>
    <div style={{ alignItems: "center", background: `linear-gradient(135deg, ${palette.goldSoft}, ${palette.terracotta})`, borderRadius: 999, color: palette.ink, display: "flex", fontSize: small ? 20 : 34, fontWeight: 800, height: small ? 42 : 68, justifyContent: "center", width: small ? 42 : 68 }}>A</div>
    <div style={{ color: light ? palette.paper : palette.ink, fontFamily: "Georgia, serif", fontSize: small ? 26 : 42, fontWeight: 700, letterSpacing: -1 }}>Arunika</div>
  </div>
);

const Eyebrow: React.FC<{ readonly children: ReactNode; readonly light?: boolean }> = ({ children, light = false }) => (
  <div style={{ color: light ? palette.goldSoft : palette.terracotta, fontSize: 20, fontWeight: 800, letterSpacing: 4, textTransform: "uppercase" }}>{children}</div>
);

const MiniChip: React.FC<{ readonly children: ReactNode; readonly accent?: string }> = ({ children, accent = palette.gold }) => (
  <div style={{ alignItems: "center", background: palette.paper, border: `1px solid ${palette.line}`, borderRadius: 999, color: palette.ink, display: "flex", fontSize: 18, fontWeight: 700, gap: 10, padding: "12px 18px" }}>
    <span style={{ background: accent, borderRadius: 999, height: 10, width: 10 }} />
    {children}
  </div>
);

const Header: React.FC<{ readonly title?: string; readonly subtitle?: string }> = ({ title = "Hari Ini", subtitle = "Senin, 24 Agustus" }) => (
  <div style={{ alignItems: "flex-start", display: "flex", justifyContent: "space-between", padding: "34px 32px 22px" }}>
    <div>
      <div style={{ color: palette.terracotta, fontSize: 12, fontWeight: 800, letterSpacing: 1.3 }}>{subtitle.toUpperCase()}</div>
      <div style={{ color: palette.ink, fontFamily: "Georgia, serif", fontSize: 29, fontWeight: 700, lineHeight: 1.05, marginTop: 7 }}>{title}</div>
    </div>
    <div style={{ alignItems: "center", background: palette.paper, border: `1px solid ${palette.goldSoft}`, borderRadius: 999, color: palette.gold, display: "flex", fontSize: 22, height: 42, justifyContent: "center", width: 42 }}>☼</div>
  </div>
);

const Nav: React.FC<{ readonly active: string }> = ({ active }) => {
  const items = ["Hari Ini", "Ritual", "Momen", "Taman"];
  return <div style={{ background: palette.paper, borderTop: `1px solid ${palette.line}`, bottom: 0, display: "flex", justifyContent: "space-around", padding: "18px 18px 22px", position: "absolute", width: "100%" }}>{items.map((item) => <div key={item} style={{ color: item === active ? palette.terracotta : palette.muted, fontSize: 11, fontWeight: 800, textAlign: "center" }}><div style={{ fontSize: 20, marginBottom: 4 }}>{item === "Hari Ini" ? "☼" : item === "Ritual" ? "✓" : item === "Momen" ? "✦" : "⌘"}</div>{item}</div>)}</div>;
};

const Progress: React.FC<{ readonly value: number; readonly accent?: string }> = ({ value, accent = palette.terracotta }) => (
  <div style={{ background: "rgba(53,41,31,.11)", borderRadius: 99, height: 9, overflow: "hidden", width: "100%" }}><div style={{ background: accent, borderRadius: 99, height: "100%", width: `${value * 100}%` }} /></div>
);

const ScreenCard: React.FC<{ readonly children: ReactNode; readonly background?: string; readonly style?: React.CSSProperties }> = ({ children, background = palette.paper, style }) => (
  <div style={{ background, border: `1px solid ${palette.line}`, borderRadius: 22, boxShadow: "0 10px 24px rgba(53,41,31,.07)", padding: 18, ...style }}>{children}</div>
);

const Screen: React.FC<{ readonly kind: ScreenKind; readonly portrait?: boolean }> = ({ kind, portrait = false }) => {
  const scale = portrait ? 1.28 : 1;
  const width = 330 * scale;
  const height = 650 * scale;
  const content = (() => {
    switch (kind) {
      case "today":
        return <><Header title="Selamat pagi, Nara." subtitle="Senin, 24 Agustus" /><div style={{ padding: "0 22px 96px" }}><div style={{ background: `linear-gradient(135deg, #FFE7B4, #E7AA79)`, borderRadius: 26, color: palette.ink, padding: 22 }}><div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 1.6 }}>ENERGI HARI INI</div><div style={{ fontFamily: "Georgia, serif", fontSize: 25, fontWeight: 700, lineHeight: 1.08, margin: "18px 0 12px" }}>1 dari 3 ritual<br />sudah dirayakan.</div><Progress value={0.33} accent={palette.terracotta} /><div style={{ display: "flex", fontSize: 11, fontWeight: 800, justifyContent: "space-between", marginTop: 9 }}><span>33% hari ini</span><span>Rayakan →</span></div></div><div style={{ color: palette.terracotta, fontSize: 10, fontWeight: 800, letterSpacing: 1.4, margin: "26px 0 9px" }}>LANGKAH HARI INI</div><ScreenCard><div style={{ alignItems: "center", display: "flex", gap: 14 }}><div style={{ alignItems: "center", background: palette.sageSoft, border: `2px solid ${palette.sage}`, borderRadius: 999, color: palette.sage, display: "flex", fontSize: 22, height: 48, justifyContent: "center", width: 48 }}>+</div><div><div style={{ color: palette.terracotta, fontSize: 10, fontWeight: 800 }}>MALAM</div><div style={{ fontFamily: "Georgia, serif", fontSize: 18, fontWeight: 700, marginTop: 4 }}>Cerita sebelum tidur</div><div style={{ color: palette.muted, fontSize: 10, marginTop: 4 }}>Satu cerita, satu pelukan.</div></div></div></ScreenCard><div style={{ color: palette.terracotta, fontSize: 10, fontWeight: 800, letterSpacing: 1.4, margin: "26px 0 9px" }}>MOMEN TERBARU</div><ScreenCard background={palette.terracottaSoft}><div style={{ color: palette.terracotta, fontSize: 10, fontWeight: 800 }}>BERSAMA</div><div style={{ fontFamily: "Georgia, serif", fontSize: 18, fontWeight: 700, marginTop: 7 }}>Hujan sore</div><div style={{ color: palette.muted, fontSize: 11, lineHeight: 1.4, marginTop: 6 }}>Kami menari di teras.</div></ScreenCard></div><Nav active="Hari Ini" /></>;
      case "rituals":
        return <><Header title="Ritual kecil" subtitle="Kebiasaan yang dipilih" /><div style={{ padding: "0 22px 96px" }}><div style={{ color: palette.muted, fontSize: 12, lineHeight: 1.45, marginBottom: 18 }}>Jeda sederhana yang terasa milik kalian. Tidak perlu sempurna.</div>{[["Cerita sebelum tidur", "Malam", palette.terracottaSoft, palette.terracotta], ["Tiga hal yang disyukuri", "Malam", palette.goldSoft, palette.gold], ["Jalan sebentar", "Sore", palette.sageSoft, palette.sage]].map(([title, time, bg, accent]) => <ScreenCard key={String(title)} background={String(bg)} style={{ marginBottom: 12 }}><div style={{ alignItems: "center", display: "flex", gap: 14 }}><div style={{ alignItems: "center", border: `2px solid ${String(accent)}`, borderRadius: 999, color: String(accent), display: "flex", fontSize: 22, height: 48, justifyContent: "center", width: 48 }}>✓</div><div style={{ flex: 1 }}><div style={{ color: String(accent), fontSize: 10, fontWeight: 800 }}>{String(time).toUpperCase()}</div><div style={{ fontFamily: "Georgia, serif", fontSize: 17, fontWeight: 700, marginTop: 4 }}>{String(title)}</div><div style={{ color: palette.muted, fontSize: 10, marginTop: 5 }}>Sen · Sel · Rab · Kam · Jum</div></div><div style={{ color: palette.muted, fontSize: 20 }}>⋮</div></div></ScreenCard>)}</div><div style={{ alignItems: "center", background: palette.sage, borderRadius: 999, bottom: 83, color: palette.paper, display: "flex", fontSize: 12, fontWeight: 800, gap: 8, padding: "13px 19px", position: "absolute", right: 22 }}>+ Buat ritual</div><Nav active="Ritual" /></>;
      case "ritual-editor":
        return <><Header title="Buat ritual baru" subtitle="Satu jeda untuk bersama" /><div style={{ padding: "0 22px 30px" }}><ScreenCard><div style={{ color: palette.muted, fontSize: 10, fontWeight: 800, letterSpacing: 1.2 }}>NAMA RITUAL</div><div style={{ borderBottom: `1px solid ${palette.goldSoft}`, fontFamily: "Georgia, serif", fontSize: 20, margin: "12px 0 24px", paddingBottom: 10 }}>Jalan sore tanpa layar</div><div style={{ color: palette.muted, fontSize: 10, fontWeight: 800, letterSpacing: 1.2 }}>WAKTU YANG TERASA PAS</div><div style={{ display: "flex", gap: 7, margin: "12px 0 24px" }}>{["Pagi", "Sore", "Malam"].map((item) => <div key={item} style={{ background: item === "Sore" ? palette.sageSoft : palette.ivory, border: `1px solid ${item === "Sore" ? palette.sage : palette.line}`, borderRadius: 12, color: item === "Sore" ? palette.sage : palette.muted, fontSize: 11, fontWeight: 800, padding: "10px 12px" }}>{item}</div>)}</div><div style={{ color: palette.muted, fontSize: 10, fontWeight: 800, letterSpacing: 1.2 }}>HARI BERULANG</div><div style={{ display: "flex", gap: 6, marginTop: 12 }}>{["S", "S", "R", "K", "J", "S", "M"].map((item, i) => <div key={`${item}-${i}`} style={{ alignItems: "center", background: [0, 1, 2, 3, 4].includes(i) ? palette.sage : palette.ivory, borderRadius: 12, color: [0, 1, 2, 3, 4].includes(i) ? palette.paper : palette.muted, display: "flex", fontSize: 11, fontWeight: 800, height: 36, justifyContent: "center", width: 34 }}>{item}</div>)}</div></ScreenCard><div style={{ background: palette.sage, borderRadius: 18, color: palette.paper, fontSize: 14, fontWeight: 800, marginTop: 18, padding: 16, textAlign: "center" }}>Simpan ritual</div></div></>;
      case "moments":
        return <><Header title="Momen yang ingin diingat" subtitle="Arsip hangat" /><div style={{ display: "flex", gap: 8, overflow: "hidden", padding: "0 22px 18px" }}>{["Semua", "Tawa", "Belajar", "Bersama"].map((item, i) => <div key={item} style={{ background: i === 0 ? palette.terracotta : palette.paper, border: `1px solid ${i === 0 ? palette.terracotta : palette.line}`, borderRadius: 13, color: i === 0 ? palette.paper : palette.muted, fontSize: 11, fontWeight: 800, padding: "10px 13px", whiteSpace: "nowrap" }}>{item}</div>)}</div><div style={{ padding: "0 22px 96px" }}>{[["Hujan sore", "Kami menari di teras.", palette.terracottaSoft, "Tawa"], ["Buku pertama", "Halaman ini dibaca tiga kali.", palette.sageSoft, "Belajar"], ["Sarapan pelan", "Tidak ada yang terburu-buru.", palette.goldSoft, "Bersama"]].map(([title, note, bg, tag]) => <ScreenCard key={String(title)} background={String(bg)} style={{ marginBottom: 12 }}><div style={{ color: palette.terracotta, fontSize: 10, fontWeight: 800 }}>{String(tag).toUpperCase()}</div><div style={{ fontFamily: "Georgia, serif", fontSize: 20, fontWeight: 700, marginTop: 8 }}>{String(title)}</div><div style={{ color: palette.muted, fontSize: 11, lineHeight: 1.45, marginTop: 6 }}>{String(note)}</div><div style={{ color: palette.muted, fontSize: 10, marginTop: 12 }}>24 Agustus 2026</div></ScreenCard>)}</div><div style={{ alignItems: "center", background: palette.terracotta, borderRadius: 999, bottom: 83, color: palette.paper, display: "flex", fontSize: 12, fontWeight: 800, gap: 8, padding: "13px 19px", position: "absolute", right: 22 }}>+ Catat momen</div><Nav active="Momen" /></>;
      case "moment-editor":
        return <><Header title="Catat momen" subtitle="Satu foto, satu kalimat" /><div style={{ padding: "0 22px 28px" }}><div style={{ alignItems: "center", background: palette.sageSoft, border: `1px solid ${palette.sage}`, borderRadius: 24, color: palette.sage, display: "flex", flexDirection: "column", height: 138, justifyContent: "center" }}><div style={{ fontSize: 32 }}>⌾</div><div style={{ fontSize: 11, fontWeight: 800, marginTop: 7 }}>Tambah foto (opsional)</div></div><div style={{ borderBottom: `1px solid ${palette.goldSoft}`, fontFamily: "Georgia, serif", fontSize: 20, marginTop: 22, padding: "10px 0" }}>Hujan sore</div><div style={{ borderBottom: `1px solid ${palette.goldSoft}`, color: palette.muted, fontSize: 12, lineHeight: 1.5, marginTop: 12, padding: "10px 0" }}>Kami menari di teras sampai lampu menyala.</div><div style={{ color: palette.terracotta, fontSize: 10, fontWeight: 800, letterSpacing: 1.2, marginTop: 24 }}>RASANYA SEPERTI…</div><div style={{ display: "flex", gap: 7, marginTop: 11 }}>{["Tawa", "Belajar", "Bersama"].map((item, i) => <div key={item} style={{ background: i === 0 ? palette.terracottaSoft : palette.paper, border: `1px solid ${i === 0 ? palette.terracotta : palette.line}`, borderRadius: 12, color: i === 0 ? palette.terracotta : palette.muted, fontSize: 11, fontWeight: 800, padding: "10px 12px" }}>{item}</div>)}</div><div style={{ background: palette.terracotta, borderRadius: 18, color: palette.paper, fontSize: 14, fontWeight: 800, marginTop: 24, padding: 16, textAlign: "center" }}>Simpan momen</div></div></>;
      case "garden":
        return <><Header title="Taman yang kalian tumbuhkan" subtitle="Ruang keluarga" /><div style={{ padding: "0 22px 96px" }}><ScreenCard><div style={{ color: palette.sage, fontSize: 10, fontWeight: 800, letterSpacing: 1.2 }}>BENANG-BENANG YANG TERHUBUNG</div><div style={{ alignItems: "center", display: "flex", height: 260, justifyContent: "center", position: "relative" }}><div style={{ alignItems: "center", background: `linear-gradient(135deg, #FFE7B4, #E7AA79)`, borderRadius: 999, color: palette.ink, display: "flex", flexDirection: "column", fontSize: 14, fontWeight: 800, height: 82, justifyContent: "center", position: "absolute", width: 82, zIndex: 2 }}>☼<span style={{ fontSize: 10, marginTop: 4 }}>8 momen</span></div>{[["N", 40, 28], ["A", 198, 22], ["K", 35, 177], ["R", 205, 173]].map(([initial, left, top]) => <div key={String(initial)} style={{ alignItems: "center", background: palette.paper, border: `2px solid ${palette.goldSoft}`, borderRadius: 999, color: palette.gold, display: "flex", fontFamily: "Georgia, serif", fontSize: 17, fontWeight: 700, height: 54, justifyContent: "center", left, position: "absolute", top, width: 54 }}>{String(initial)}</div>)}<svg height="260" style={{ position: "absolute" }} width="280"><line stroke={palette.goldSoft} strokeWidth="2" x1="140" x2="66" y1="130" y2="55" /><line stroke={palette.goldSoft} strokeWidth="2" x1="140" x2="220" y1="130" y2="50" /><line stroke={palette.goldSoft} strokeWidth="2" x1="140" x2="62" y1="130" y2="205" /><line stroke={palette.goldSoft} strokeWidth="2" x1="140" x2="222" y1="130" y2="201" /></svg></div><div style={{ color: palette.muted, fontSize: 11, lineHeight: 1.45 }}>Setiap momen adalah cahaya. Setiap ritual adalah akar.</div></ScreenCard><div style={{ color: palette.sage, fontSize: 10, fontWeight: 800, letterSpacing: 1.2, margin: "24px 0 10px" }}>ORANG-ORANG DI SINI</div><ScreenCard><div style={{ alignItems: "center", display: "flex", gap: 12 }}><div style={{ alignItems: "center", background: palette.goldSoft, borderRadius: 999, color: palette.gold, display: "flex", fontFamily: "Georgia, serif", fontSize: 17, height: 42, justifyContent: "center", width: 42 }}>N</div><div><div style={{ fontSize: 14, fontWeight: 800 }}>Nara</div><div style={{ color: palette.muted, fontSize: 11, marginTop: 3 }}>Keluarga</div></div></div></ScreenCard></div><Nav active="Taman" /></>;
      case "scrapbook":
        return <><Header title="Ekspor scrapbook" subtitle="Privasi & kenyamanan" /><div style={{ padding: "0 22px 30px" }}><ScreenCard background={palette.goldSoft}><div style={{ color: palette.gold, fontSize: 10, fontWeight: 800, letterSpacing: 1.2 }}>UNTUK KALIAN SIMPAN</div><div style={{ fontFamily: "Georgia, serif", fontSize: 24, fontWeight: 700, lineHeight: 1.12, marginTop: 14 }}>Bawa pulang<br />cerita kalian.</div><div style={{ color: palette.muted, fontSize: 11, lineHeight: 1.45, marginTop: 10 }}>Jadikan momen dan ritual dalam satu PDF yang bisa dibagikan kapan saja.</div><div style={{ background: palette.ink, borderRadius: 16, color: palette.paper, fontSize: 13, fontWeight: 800, marginTop: 18, padding: 14, textAlign: "center" }}>Ekspor scrapbook</div></ScreenCard><ScreenCard style={{ marginTop: 14 }}><div style={{ alignItems: "center", display: "flex", gap: 11 }}><div style={{ fontSize: 24 }}>⌁</div><div><div style={{ fontSize: 13, fontWeight: 800 }}>Lokal secara default</div><div style={{ color: palette.muted, fontSize: 10, marginTop: 3 }}>Tidak perlu akun. Anda yang memilih kapan berbagi.</div></div></div></ScreenCard></div></>;
      case "privacy":
        return <><Header title="Dalam kendali" subtitle="Pengaturan Arunika" /><div style={{ padding: "0 22px 30px" }}><ScreenCard background={palette.sageSoft}><div style={{ color: palette.sage, fontSize: 10, fontWeight: 800, letterSpacing: 1.2 }}>PRIVAT SECARA DEFAULT</div><div style={{ fontFamily: "Georgia, serif", fontSize: 22, fontWeight: 700, lineHeight: 1.12, marginTop: 12 }}>Ruang tenang<br />untuk keluarga.</div><div style={{ color: palette.muted, fontSize: 11, lineHeight: 1.45, marginTop: 10 }}>Catatan inti tinggal di perangkat. Iklan hanya di area jelajah.</div></ScreenCard><div style={{ color: palette.terracotta, fontSize: 10, fontWeight: 800, letterSpacing: 1.2, margin: "24px 0 10px" }}>DUKUNG ARUNIKA</div><ScreenCard><div style={{ alignItems: "center", display: "flex", gap: 12 }}><div style={{ alignItems: "center", background: palette.goldSoft, borderRadius: 15, display: "flex", fontSize: 24, height: 46, justifyContent: "center", width: 46 }}>✦</div><div style={{ flex: 1 }}><div style={{ fontFamily: "Georgia, serif", fontSize: 17, fontWeight: 700 }}>Bebas Iklan</div><div style={{ color: palette.muted, fontSize: 10, marginTop: 4 }}>Satu kali US$4.99</div></div></div><div style={{ background: palette.terracotta, borderRadius: 15, color: palette.paper, fontSize: 12, fontWeight: 800, marginTop: 15, padding: 13, textAlign: "center" }}>Hapus iklan</div></ScreenCard></div></>;
    }
  })();
  return <div style={{ background: palette.ivory, border: "8px solid #40342A", borderRadius: 38, boxShadow: "0 35px 70px rgba(53,41,31,.24)", height, overflow: "hidden", position: "relative", width }}>{content}</div>;
};

const Phone: React.FC<{ readonly kind: ScreenKind; readonly frame: number; readonly delay?: number; readonly scale?: number }> = ({ kind, frame, delay = 0, scale = 1 }) => (
  <div style={{ opacity: appear(frame, delay), scale: interpolate(frame, [delay, delay + 24], [0.9, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: Easing.spring({ damping: 18 }) }) * scale, translate: `0px ${rise(frame, delay, 70)}px` }}><Screen kind={kind} /></div>
);

const StoryScene: React.FC<{ readonly durationInFrames: number; readonly eyebrow: string; readonly title: string; readonly body: string; readonly kind: ScreenKind; readonly background?: string; readonly light?: boolean; readonly chips?: ReactNode }> = ({ durationInFrames, eyebrow, title, body, kind, background, light = false, chips }) => {
  const frame = useCurrentFrame();
  return <Scene durationInFrames={durationInFrames} background={background} light={light}><div style={{ alignItems: "center", display: "flex", height: "100%", justifyContent: "space-between", padding: "80px 120px", position: "relative" }}><div style={{ display: "flex", flexDirection: "column", justifyContent: "center", maxWidth: 780, paddingRight: 70, zIndex: 2 }}><Brand light={light} small /><div style={{ marginTop: 80 }}><Eyebrow light={light}>{eyebrow}</Eyebrow><div style={{ color: light ? palette.paper : palette.ink, fontFamily: "Georgia, serif", fontSize: 72, fontWeight: 700, letterSpacing: -2, lineHeight: 1.02, marginTop: 28, opacity: appear(frame, 8), translate: `0px ${rise(frame, 8, 48)}px` }}>{title}</div><div style={{ color: light ? "#d9e0d9" : palette.muted, fontSize: 29, lineHeight: 1.45, marginTop: 28, maxWidth: 640, opacity: appear(frame, 16), translate: `0px ${rise(frame, 16, 34)}px` }}>{body}</div><div style={{ display: "flex", gap: 14, marginTop: 38, opacity: appear(frame, 24), translate: `0px ${rise(frame, 24, 22)}px` }}>{chips}</div></div></div><div style={{ alignItems: "center", display: "flex", justifyContent: "center", position: "relative", width: 650 }}><div style={{ background: light ? "rgba(242,216,160,.14)" : "rgba(242,216,160,.35)", borderRadius: 999, height: 560, position: "absolute", width: 560 }} /><Phone kind={kind} frame={frame} delay={10} /></div></div></Scene>;
};

export const ArunikaPromo: React.FC = () => {
  const { fps } = useVideoConfig();
  const intro = 3.5 * fps;
  const today = 5 * fps;
  const ritual = 5 * fps;
  const moment = 5 * fps;
  const garden = 5 * fps;
  const privacy = 5 * fps;
  const outro = 3.5 * fps;
  const start = [0, intro, intro + today, intro + today + ritual, intro + today + ritual + moment, intro + today + ritual + moment + garden, intro + today + ritual + moment + garden + privacy];
  return <AbsoluteFill style={{ background: palette.ivory, fontFamily: "Arial, sans-serif" }}><Sequence from={start[0]} durationInFrames={intro} layout="none" name="01 Intro"><Intro durationInFrames={intro} /></Sequence><Sequence from={start[1]} durationInFrames={today} layout="none" name="02 Today"><StoryScene durationInFrames={today} eyebrow="Hari ini" title="Beri ruang untuk yang penting." body="Satu pandangan hangat untuk sapaan, ritual, recap, dan momen yang ingin diingat." kind="today" chips={<><MiniChip accent={palette.terracotta}>Ritual kecil</MiniChip><MiniChip accent={palette.sage}>Offline-first</MiniChip></>} /></Sequence><Sequence from={start[2]} durationInFrames={ritual} layout="none" name="03 Ritual"><StoryScene durationInFrames={ritual} background={palette.ink} light eyebrow="Ritual" title="Kebersamaan tidak perlu sempurna." body="Pilih jeda yang terasa milik kalian. Rayakan dengan satu ketukan, tanpa streak yang menghakimi." kind="rituals" chips={<><MiniChip accent={palette.gold}>Hadir</MiniChip><MiniChip accent={palette.sage}>Berulang</MiniChip></>} /></Sequence><Sequence from={start[3]} durationInFrames={moment} layout="none" name="04 Moments"><StoryScene durationInFrames={moment} eyebrow="Momen" title="Satu foto. Satu kalimat. Satu cerita." body="Simpan tawa, percakapan, dan hari biasa yang kelak terasa luar biasa." kind="moments" chips={<><MiniChip accent={palette.terracotta}>Foto opsional</MiniChip><MiniChip accent={palette.gold}>Tag suasana</MiniChip></>} /></Sequence><Sequence from={start[4]} durationInFrames={garden} layout="none" name="05 Garden"><StoryScene durationInFrames={garden} background={palette.sage} light eyebrow="Taman" title="Lihat benang yang kalian tumbuhkan." body="Momen dan ritual bertemu menjadi constellation kecil milik keluarga." kind="garden" chips={<><MiniChip accent={palette.gold}>Taman keluarga</MiniChip></>} /></Sequence><Sequence from={start[5]} durationInFrames={privacy} layout="none" name="06 Privacy"><StoryScene durationInFrames={privacy} eyebrow="Dalam kendali" title="Privat secara default." body="Catatan inti tinggal di perangkat. Pilih sendiri kapan ingin mengekspor, berbagi, atau bebas iklan." kind="privacy" chips={<><MiniChip accent={palette.sage}>Data lokal</MiniChip><MiniChip accent={palette.terracotta}>US$4.99 Bebas Iklan</MiniChip></>} /></Sequence><Sequence from={start[6]} durationInFrames={outro} layout="none" name="07 Outro"><Outro durationInFrames={outro} /></Sequence></AbsoluteFill>;
};

const Intro: React.FC<{ readonly durationInFrames: number }> = ({ durationInFrames }) => { const frame = useCurrentFrame(); return <Scene durationInFrames={durationInFrames}><div style={{ alignItems: "center", display: "flex", flexDirection: "column", height: "100%", justifyContent: "center", position: "relative" }}><div style={{ opacity: appear(frame), scale: interpolate(frame, [0, 24], [0.84, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: Easing.spring({ damping: 16 }) }) }}><Brand /></div><div style={{ color: palette.muted, fontSize: 33, marginTop: 30, opacity: appear(frame, 14), translate: `0px ${rise(frame, 14, 30)}px` }}>Tumbuh bersama, satu hari pada satu waktu.</div><div style={{ background: palette.terracotta, borderRadius: 999, height: 8, marginTop: 34, opacity: appear(frame, 26), width: 92 }} /></div></Scene>; };

const Outro: React.FC<{ readonly durationInFrames: number }> = ({ durationInFrames }) => { const frame = useCurrentFrame(); return <Scene durationInFrames={durationInFrames} background={palette.ink} light><div style={{ alignItems: "center", display: "flex", flexDirection: "column", height: "100%", justifyContent: "center" }}><div style={{ opacity: appear(frame), translate: `0px ${rise(frame, 0, 34)}px` }}><Brand light /></div><div style={{ color: palette.goldSoft, fontFamily: "Georgia, serif", fontSize: 37, fontWeight: 700, marginTop: 30, opacity: appear(frame, 12), translate: `0px ${rise(frame, 12, 26)}px` }}>Catat hari ini. Tumbuh bersama.</div><div style={{ color: "#D9E0D9", fontSize: 21, marginTop: 16, opacity: appear(frame, 22) }}>Arunika: Tumbuh Bersama</div></div></Scene>; };

type StoreShotProps = { readonly kind: ScreenKind; readonly eyebrow: string; readonly title: string; readonly detail: string; readonly accent: string };

const StoreShot: React.FC<StoreShotProps> = ({ kind, eyebrow, title, detail, accent }) => { const frame = useCurrentFrame() + 60; return <AbsoluteFill style={{ background: `linear-gradient(155deg, ${palette.ivory} 0%, ${accent} 150%)`, color: palette.ink, fontFamily: "Arial, sans-serif" }}><div style={{ padding: "92px 78px 0" }}><Brand small /><div style={{ color: palette.terracotta, fontSize: 18, fontWeight: 800, letterSpacing: 3, marginTop: 82, textTransform: "uppercase" }}>{eyebrow}</div><div style={{ fontFamily: "Georgia, serif", fontSize: 60, fontWeight: 700, letterSpacing: -1.8, lineHeight: 1.02, marginTop: 20, opacity: appear(frame, 8), translate: `0px ${rise(frame, 8, 34)}px` }}>{title}</div><div style={{ color: palette.muted, fontSize: 24, lineHeight: 1.42, marginTop: 22, maxWidth: 860, opacity: appear(frame, 16), translate: `0px ${rise(frame, 16, 24)}px` }}>{detail}</div></div><div style={{ alignItems: "flex-start", display: "flex", justifyContent: "center", marginTop: 62 }}><div style={{ opacity: appear(frame, 22), scale: interpolate(frame, [0, 26], [0.92, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: Easing.spring({ damping: 17 }) }), translate: `0px ${rise(frame, 22, 54)}px` }}><Screen kind={kind} portrait /></div></div><div style={{ bottom: 56, color: palette.muted, fontSize: 17, fontWeight: 700, left: 78, position: "absolute" }}>arunika · tumbuh bersama</div></AbsoluteFill>; };

const storeShots: Array<StoreShotProps & { readonly id: string }> = [
  { id: "01-today", kind: "today", eyebrow: "HARI INI", title: "Beri ruang untuk yang penting.", detail: "Sapaan, ritual, recap, dan momen dalam satu pandangan yang hangat.", accent: "#FFE7B4" },
  { id: "02-rituals", kind: "rituals", eyebrow: "RITUAL", title: "Kebiasaan kecil yang terasa milik kalian.", detail: "Pilih jeda dan rayakan saat sempat—tanpa streak yang menghakimi.", accent: "#D9E8D9" },
  { id: "03-ritual-editor", kind: "ritual-editor", eyebrow: "BUAT RITUAL", title: "Buat ruang untuk hadir.", detail: "Atur waktu dan hari sesuai ritme keluarga.", accent: "#E7E0EE" },
  { id: "04-moments", kind: "moments", eyebrow: "MOMEN", title: "Simpan cerita yang ingin diingat.", detail: "Foto opsional, satu kalimat, dan tag suasana yang terasa jujur.", accent: "#F6DCD3" },
  { id: "05-moment-editor", kind: "moment-editor", eyebrow: "CATAT MOMEN", title: "Satu foto. Satu kalimat. Satu momen.", detail: "Jadikan hari biasa punya tempat untuk pulang.", accent: "#D7E7D8" },
  { id: "06-garden", kind: "garden", eyebrow: "TAMAN", title: "Lihat benang kebersamaan.", detail: "Momen dan ritual bertemu menjadi constellation kecil milik keluarga.", accent: "#D1E2D3" },
  { id: "07-scrapbook", kind: "scrapbook", eyebrow: "SCRAPBOOK", title: "Bawa pulang cerita kalian.", detail: "Ekspor kenangan menjadi PDF ketika ingin disimpan atau dibagikan.", accent: "#F4E2B7" },
  { id: "08-privacy-ads", kind: "privacy", eyebrow: "DALAM KENDALI", title: "Privat secara default.", detail: "Data lokal. Banner stabil di jelajah. Bebas iklan satu kali US$4.99.", accent: "#DDE8DD" },
];

const FeatureGraphic: React.FC = () => {
  const frame = useCurrentFrame() + 60;
  return <AbsoluteFill style={{ background: `linear-gradient(122deg, ${palette.ivory} 0%, #F6E7C3 58%, #D9E9DA 100%)`, color: palette.ink, fontFamily: "Arial, sans-serif", overflow: "hidden" }}>
    <div style={{ background: "rgba(255,255,255,.36)", border: `1px solid rgba(255,255,255,.55)`, borderRadius: 999, height: 580, position: "absolute", right: -170, top: -220, width: 580 }} />
    <div style={{ background: "rgba(185,102,82,.12)", borderRadius: 999, bottom: -270, height: 520, position: "absolute", right: 210, width: 520 }} />
    <div style={{ display: "flex", height: "100%", justifyContent: "space-between", padding: "76px 74px", position: "relative" }}>
      <div style={{ display: "flex", flexDirection: "column", justifyContent: "center", maxWidth: 560, opacity: appear(frame), translate: `0px ${rise(frame, 0, 26)}px` }}>
        <Brand small />
        <div style={{ color: palette.terracotta, fontSize: 18, fontWeight: 800, letterSpacing: 3.2, marginTop: 42 }}>RUANG KELUARGA YANG HANGAT</div>
        <div style={{ fontFamily: "Georgia, serif", fontSize: 53, fontWeight: 700, letterSpacing: -1.4, lineHeight: 1.02, marginTop: 16 }}>Ritual kecil.<br />Momen hangat.<br />Tumbuh bersama.</div>
        <div style={{ color: palette.muted, fontSize: 21, lineHeight: 1.35, marginTop: 22, maxWidth: 470 }}>Arunika menyimpan cerita yang ingin kalian ingat—privat, sederhana, dan tetap milik keluarga.</div>
      </div>
      <div style={{ alignItems: "center", display: "flex", justifyContent: "center", position: "relative", width: 340 }}>
        <div style={{ background: "rgba(255,253,248,.62)", border: `1px solid ${palette.goldSoft}`, borderRadius: 34, boxShadow: "0 26px 60px rgba(53,41,31,.12)", height: 290, position: "relative", rotate: "7deg", width: 290 }}>
          <div style={{ alignItems: "center", display: "flex", flexDirection: "column", height: "100%", justifyContent: "center", position: "relative" }}>
            <div style={{ alignItems: "center", background: `linear-gradient(135deg, ${palette.goldSoft}, ${palette.terracotta})`, borderRadius: 999, color: palette.ink, display: "flex", fontSize: 28, fontWeight: 800, height: 62, justifyContent: "center", width: 62 }}>A</div>
            <div style={{ color: palette.ink, fontFamily: "Georgia, serif", fontSize: 30, fontWeight: 700, marginTop: 13 }}>Arunika</div>
            <div style={{ color: palette.muted, fontSize: 13, marginTop: 7 }}>Tumbuh Bersama</div>
            <div style={{ display: "flex", gap: 9, marginTop: 29 }}><MiniChip accent={palette.terracotta}>Momen</MiniChip><MiniChip accent={palette.sage}>Ritual</MiniChip></div>
          </div>
        </div>
        <div style={{ alignItems: "center", background: palette.sage, border: "5px solid rgba(255,253,248,.72)", borderRadius: 999, bottom: 22, color: palette.paper, display: "flex", fontSize: 21, height: 72, justifyContent: "center", position: "absolute", right: 13, width: 72 }}>✦</div>
      </div>
    </div>
    <div style={{ bottom: 27, color: palette.muted, fontSize: 14, fontWeight: 800, left: 74, letterSpacing: 1.2, position: "absolute" }}>ARUNIKA · TUMBUH BERSAMA</div>
  </AbsoluteFill>;
};

export const MyComposition = () => <Composition id="ArunikaPromo" component={ArunikaPromo} durationInFrames={32 * 30} fps={30} height={1080} width={1920} />;

export const StoreCompositions = () => <Folder name="Store-Screenshots"><Still id="feature-graphic" component={FeatureGraphic} width={1024} height={500} />{storeShots.map((shot) => <Still key={shot.id} id={shot.id} component={StoreShot} width={1080} height={1920} defaultProps={shot} />)}</Folder>;
