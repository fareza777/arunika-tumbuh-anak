import {
  AbsoluteFill,
  CanvasImage,
  Composition,
  Easing,
  interpolate,
  Sequence,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import type { ReactNode } from "react";

const palette = {
  ink: "#1e2a23",
  muted: "#657267",
  ivory: "#f8f5ed",
  cream: "#fffdf8",
  gold: "#d2a33b",
  goldSoft: "#ead39a",
  sage: "#9db9a1",
  green: "#4e8764",
  line: "rgba(30, 42, 35, 0.12)",
};

type SceneProps = {
  children: ReactNode;
  durationInFrames: number;
};

const ease = Easing.bezier(0.16, 1, 0.3, 1);

const fadeValue = (frame: number, durationInFrames: number) =>
  interpolate(
    frame,
    [0, 18, Math.max(18, durationInFrames - 18), durationInFrames],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp", easing: ease },
  );

const rise = (frame: number, distance = 56, delay = 0) =>
  interpolate(frame, [delay, delay + 22], [distance, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: ease,
  });

const appear = (frame: number, delay = 0) =>
  interpolate(frame, [delay, delay + 18], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: ease,
  });

const SceneFrame: React.FC<SceneProps> = ({ children, durationInFrames }) => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill
      style={{
        opacity: fadeValue(frame, durationInFrames),
        overflow: "hidden",
      }}
    >
      {children}
    </AbsoluteFill>
  );
};

const BrandMark: React.FC<{ size?: number }> = ({ size = 84 }) => (
  <div
    style={{
      alignItems: "center",
      background: palette.ink,
      border: `2px solid ${palette.gold}`,
      borderRadius: size,
      color: palette.goldSoft,
      display: "flex",
      fontSize: size * 0.42,
      fontWeight: 800,
      height: size,
      justifyContent: "center",
      letterSpacing: -2,
      width: size,
    }}
  >
    A
  </div>
);

const Eyebrow: React.FC<{ children: ReactNode; light?: boolean }> = ({
  children,
  light = false,
}) => (
  <div
    style={{
      color: light ? palette.goldSoft : palette.gold,
      fontSize: 22,
      fontWeight: 800,
      letterSpacing: 4,
      textTransform: "uppercase",
    }}
  >
    {children}
  </div>
);

const PhoneShot: React.FC<{
  src: string;
  frame: number;
  delay?: number;
  width?: number;
  rotate?: number;
}> = ({ src, frame, delay = 0, width = 376, rotate = 0 }) => {
  const y = rise(frame, 90, delay);
  const opacity = appear(frame, delay);
  return (
    <div
      style={{
        opacity,
        rotate: `${rotate}deg`,
        translate: `0px ${y}px`,
        width,
      }}
    >
      <div
        style={{
          background: "#172019",
          border: "7px solid #26382b",
          borderRadius: 46,
          boxShadow: "0 28px 80px rgba(30, 42, 35, 0.28)",
          padding: 10,
        }}
      >
        <div
          style={{
            aspectRatio: "9 / 16",
            background: palette.cream,
            borderRadius: 32,
            overflow: "hidden",
            position: "relative",
          }}
        >
          <CanvasImage
            src={staticFile(`screenshots/${src}`)}
            style={{ height: "100%", objectFit: "cover", width: "100%" }}
          />
        </div>
      </div>
    </div>
  );
};

const Chip: React.FC<{
  children: ReactNode;
  frame: number;
  delay?: number;
  accent?: string;
}> = ({ children, frame, delay = 0, accent = palette.gold }) => (
  <div
    style={{
      alignItems: "center",
      background: "rgba(255, 253, 248, 0.92)",
      border: `1px solid ${palette.line}`,
      borderRadius: 999,
      boxShadow: "0 12px 28px rgba(30, 42, 35, 0.09)",
      color: palette.ink,
      display: "flex",
      fontSize: 20,
      fontWeight: 700,
      gap: 12,
      opacity: appear(frame, delay),
      padding: "16px 22px 16px 16px",
      translate: `0px ${rise(frame, 32, delay)}px`,
      whiteSpace: "nowrap",
    }}
  >
    <span
      style={{
        background: accent,
        borderRadius: 999,
        height: 12,
        width: 12,
      }}
    />
    {children}
  </div>
);

const GridGlow: React.FC<{ light?: boolean }> = ({ light = false }) => (
  <div
    style={{
      backgroundImage: `linear-gradient(${light ? "rgba(255,255,255,.08)" : "rgba(30,42,35,.055)"} 1px, transparent 1px), linear-gradient(90deg, ${light ? "rgba(255,255,255,.08)" : "rgba(30,42,35,.055)"} 1px, transparent 1px)`,
      backgroundSize: "72px 72px",
      inset: 0,
      maskImage: "linear-gradient(to bottom, black, transparent 88%)",
      opacity: 0.8,
      pointerEvents: "none",
      position: "absolute",
    }}
  />
);

const Intro: React.FC<{ durationInFrames: number }> = ({
  durationInFrames,
}) => {
  const frame = useCurrentFrame();
  return (
    <SceneFrame durationInFrames={durationInFrames}>
      <AbsoluteFill
        style={{
          alignItems: "center",
          background: `radial-gradient(circle at 50% 42%, #fffdf8 0%, ${palette.ivory} 58%, #eee7d7 100%)`,
          color: palette.ink,
          justifyContent: "center",
        }}
      >
        <GridGlow />
        <div
          style={{
            alignItems: "center",
            display: "flex",
            flexDirection: "column",
            gap: 30,
            opacity: appear(frame),
            translate: `0px ${rise(frame, 45)}px`,
          }}
        >
          <BrandMark size={118} />
          <div style={{ fontSize: 92, fontWeight: 800, letterSpacing: -4 }}>
            Arunika
          </div>
          <div style={{ color: palette.muted, fontSize: 32, fontWeight: 500 }}>
            Tumbuh kembang anak, lebih tenang.
          </div>
          <div
            style={{
              background: palette.gold,
              borderRadius: 999,
              height: 8,
              marginTop: 10,
              width: 96,
            }}
          />
        </div>
      </AbsoluteFill>
    </SceneFrame>
  );
};

const Overview: React.FC<{ durationInFrames: number }> = ({
  durationInFrames,
}) => {
  const frame = useCurrentFrame();
  return (
    <SceneFrame durationInFrames={durationInFrames}>
      <AbsoluteFill style={{ background: palette.ivory, color: palette.ink }}>
        <GridGlow />
        <div style={{ display: "flex", height: "100%", padding: "92px 130px" }}>
          <div
            style={{
              display: "flex",
              flex: 1,
              flexDirection: "column",
              justifyContent: "center",
              paddingRight: 90,
            }}
          >
            <Eyebrow>Ruang tumbuh keluarga</Eyebrow>
            <div
              style={{
                fontSize: 68,
                fontWeight: 800,
                letterSpacing: -2,
                lineHeight: 1.05,
                marginTop: 26,
                maxWidth: 700,
                opacity: appear(frame, 4),
                translate: `0px ${rise(frame, 52, 4)}px`,
              }}
            >
              Pantau dengan tenang.
            </div>
            <div
              style={{
                color: palette.muted,
                fontSize: 28,
                lineHeight: 1.45,
                marginTop: 28,
                maxWidth: 590,
                opacity: appear(frame, 12),
                translate: `0px ${rise(frame, 36, 12)}px`,
              }}
            >
              Catat tinggi dan berat, lalu lihat pola pertumbuhan anak dalam
              satu pandangan yang hangat dan mudah dipahami.
            </div>
            <div style={{ display: "flex", gap: 16, marginTop: 42 }}>
              <Chip frame={frame} delay={20}>
                Profil anak
              </Chip>
              <Chip frame={frame} delay={26} accent={palette.green}>
                Offline-first
              </Chip>
            </div>
          </div>
          <div
            style={{
              alignItems: "center",
              display: "flex",
              justifyContent: "center",
              position: "relative",
              width: 560,
            }}
          >
            <div
              style={{
                background: "rgba(210, 163, 59, 0.16)",
                borderRadius: "50%",
                height: 540,
                position: "absolute",
                width: 540,
              }}
            />
            <PhoneShot
              src="01-home-overview.png"
              frame={frame}
              width={360}
              rotate={3}
              delay={8}
            />
          </div>
        </div>
      </AbsoluteFill>
    </SceneFrame>
  );
};

const GrowthChart: React.FC<{ durationInFrames: number }> = ({
  durationInFrames,
}) => {
  const frame = useCurrentFrame();
  const graphProgress = interpolate(frame, [20, 100], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: ease,
  });
  return (
    <SceneFrame durationInFrames={durationInFrames}>
      <AbsoluteFill style={{ background: palette.ink, color: palette.cream }}>
        <GridGlow light />
        <div style={{ display: "flex", height: "100%", padding: "92px 130px" }}>
          <div
            style={{
              alignItems: "center",
              display: "flex",
              justifyContent: "center",
              position: "relative",
              width: 640,
            }}
          >
            <div
              style={{
                border: "1px solid rgba(234, 211, 154, 0.25)",
                borderRadius: "50%",
                height: 520,
                position: "absolute",
                width: 520,
              }}
            />
            <PhoneShot
              src="02-growth-chart.png"
              frame={frame}
              width={372}
              rotate={-3}
              delay={4}
            />
          </div>
          <div
            style={{
              display: "flex",
              flex: 1,
              flexDirection: "column",
              justifyContent: "center",
              paddingLeft: 70,
            }}
          >
            <Eyebrow light>Standar pertumbuhan</Eyebrow>
            <div
              style={{
                fontSize: 68,
                fontWeight: 800,
                letterSpacing: -2,
                lineHeight: 1.05,
                marginTop: 26,
                maxWidth: 720,
                opacity: appear(frame, 8),
                translate: `0px ${rise(frame, 48, 8)}px`,
              }}
            >
              Grafik WHO &amp; CDC.
            </div>
            <div
              style={{
                color: "#c0cdc1",
                fontSize: 28,
                lineHeight: 1.45,
                marginTop: 28,
                maxWidth: 610,
                opacity: appear(frame, 16),
                translate: `0px ${rise(frame, 34, 16)}px`,
              }}
            >
              Periksa tinggi, berat, BMI, dan perubahan dari waktu ke waktu
              dengan visual yang tidak menghakimi.
            </div>
            <div
              style={{
                height: 94,
                marginTop: 44,
                opacity: appear(frame, 22),
                position: "relative",
                width: 520,
              }}
            >
              {[0, 1, 2, 3].map((index) => (
                <div
                  key={index}
                  style={{
                    background: "rgba(234, 211, 154, 0.16)",
                    height: 1,
                    left: 0,
                    position: "absolute",
                    top: index * 30 + 4,
                    width: "100%",
                  }}
                />
              ))}
              <svg
                height="94"
                style={{ overflow: "visible", position: "absolute" }}
                viewBox="0 0 520 94"
                width="520"
              >
                <path
                  d="M8 82 C 95 76, 124 58, 188 62 S 286 39, 350 42 S 438 13, 512 18"
                  fill="none"
                  pathLength={1}
                  stroke={palette.goldSoft}
                  strokeDasharray={1}
                  strokeDashoffset={1 - graphProgress}
                  strokeLinecap="round"
                  strokeWidth="6"
                />
              </svg>
            </div>
          </div>
        </div>
      </AbsoluteFill>
    </SceneFrame>
  );
};

const Insight: React.FC<{ durationInFrames: number }> = ({
  durationInFrames,
}) => {
  const frame = useCurrentFrame();
  return (
    <SceneFrame durationInFrames={durationInFrames}>
      <AbsoluteFill
        style={{
          background: `linear-gradient(135deg, ${palette.cream} 0%, #f4efe3 100%)`,
          color: palette.ink,
        }}
      >
        <GridGlow />
        <div style={{ display: "flex", height: "100%", padding: "92px 130px" }}>
          <div
            style={{
              display: "flex",
              flex: 1,
              flexDirection: "column",
              justifyContent: "center",
              paddingRight: 70,
            }}
          >
            <Eyebrow>Lebih dari angka</Eyebrow>
            <div
              style={{
                fontSize: 66,
                fontWeight: 800,
                letterSpacing: -2,
                lineHeight: 1.08,
                marginTop: 26,
                maxWidth: 720,
                opacity: appear(frame, 5),
                translate: `0px ${rise(frame, 48, 5)}px`,
              }}
            >
              Baca pola, bukan sekadar angka.
            </div>
            <div
              style={{
                color: palette.muted,
                fontSize: 28,
                lineHeight: 1.45,
                marginTop: 28,
                maxWidth: 585,
                opacity: appear(frame, 14),
                translate: `0px ${rise(frame, 35, 14)}px`,
              }}
            >
              Insight persentil dan kecepatan membantu orang tua mengamati
              perkembangan dengan konteks yang lebih utuh.
            </div>
            <div style={{ display: "flex", gap: 18, marginTop: 42 }}>
              <Chip frame={frame} delay={22} accent={palette.green}>
                P57 · Tinggi
              </Chip>
              <Chip frame={frame} delay={28} accent={palette.gold}>
                P67 · Berat
              </Chip>
            </div>
          </div>
          <div
            style={{
              alignItems: "center",
              display: "flex",
              justifyContent: "center",
              position: "relative",
              width: 550,
            }}
          >
            <div
              style={{
                background: "rgba(157, 185, 161, 0.28)",
                borderRadius: "50%",
                height: 560,
                position: "absolute",
                width: 560,
              }}
            />
            <PhoneShot
              src="03-nutrition-status.png"
              frame={frame}
              width={366}
              rotate={3}
              delay={8}
            />
          </div>
        </div>
      </AbsoluteFill>
    </SceneFrame>
  );
};

const WholeChild: React.FC<{ durationInFrames: number }> = ({
  durationInFrames,
}) => {
  const frame = useCurrentFrame();
  return (
    <SceneFrame durationInFrames={durationInFrames}>
      <AbsoluteFill style={{ background: palette.ink, color: palette.cream }}>
        <GridGlow light />
        <div style={{ display: "flex", height: "100%", padding: "80px 120px" }}>
          <div
            style={{
              alignItems: "center",
              display: "flex",
              gap: 26,
              width: 720,
            }}
          >
            <PhoneShot
              src="05-milestones.png"
              frame={frame}
              width={318}
              rotate={-5}
              delay={3}
            />
            <PhoneShot
              src="07-nutrition-checklist.png"
              frame={frame}
              width={318}
              rotate={5}
              delay={14}
            />
          </div>
          <div
            style={{
              display: "flex",
              flex: 1,
              flexDirection: "column",
              justifyContent: "center",
              paddingLeft: 70,
            }}
          >
            <Eyebrow light>Perawatan yang menyeluruh</Eyebrow>
            <div
              style={{
                fontSize: 64,
                fontWeight: 800,
                letterSpacing: -2,
                lineHeight: 1.08,
                marginTop: 25,
                maxWidth: 720,
                opacity: appear(frame, 10),
                translate: `0px ${rise(frame, 48, 10)}px`,
              }}
            >
              Milestone · Imunisasi · Gizi.
            </div>
            <div
              style={{
                color: "#c0cdc1",
                fontSize: 28,
                lineHeight: 1.45,
                marginTop: 28,
                maxWidth: 610,
                opacity: appear(frame, 18),
                translate: `0px ${rise(frame, 34, 18)}px`,
              }}
            >
              Satu ruang untuk kebiasaan kecil, catatan penting, dan percakapan
              yang berarti bersama tenaga kesehatan.
            </div>
            <div style={{ display: "flex", gap: 16, marginTop: 40 }}>
              <Chip frame={frame} delay={25} accent={palette.goldSoft}>
                Catatan harian
              </Chip>
              <Chip frame={frame} delay={31} accent={palette.sage}>
                Checklist
              </Chip>
            </div>
          </div>
        </div>
      </AbsoluteFill>
    </SceneFrame>
  );
};

const Privacy: React.FC<{ durationInFrames: number }> = ({
  durationInFrames,
}) => {
  const frame = useCurrentFrame();
  return (
    <SceneFrame durationInFrames={durationInFrames}>
      <AbsoluteFill
        style={{
          background: `linear-gradient(130deg, #f2eee3 0%, ${palette.ivory} 52%, #e7e1d2 100%)`,
          color: palette.ink,
        }}
      >
        <GridGlow />
        <div style={{ display: "flex", height: "100%", padding: "92px 130px" }}>
          <div
            style={{
              alignItems: "center",
              display: "flex",
              justifyContent: "center",
              position: "relative",
              width: 600,
            }}
          >
            <div
              style={{
                background: "rgba(210, 163, 59, 0.14)",
                borderRadius: "50%",
                height: 500,
                position: "absolute",
                width: 500,
              }}
            />
            <PhoneShot
              src="08-report-settings.png"
              frame={frame}
              width={370}
              rotate={-3}
              delay={6}
            />
          </div>
          <div
            style={{
              display: "flex",
              flex: 1,
              flexDirection: "column",
              justifyContent: "center",
              paddingLeft: 70,
            }}
          >
            <Eyebrow>Dalam kendali</Eyebrow>
            <div
              style={{
                fontSize: 65,
                fontWeight: 800,
                letterSpacing: -2,
                lineHeight: 1.08,
                marginTop: 26,
                maxWidth: 680,
                opacity: appear(frame, 10),
                translate: `0px ${rise(frame, 48, 10)}px`,
              }}
            >
              Offline-first. Privat. Sederhana.
            </div>
            <div
              style={{
                color: palette.muted,
                fontSize: 28,
                lineHeight: 1.45,
                marginTop: 28,
                maxWidth: 600,
                opacity: appear(frame, 18),
                translate: `0px ${rise(frame, 34, 18)}px`,
              }}
            >
              Data inti tetap di perangkat. Iklan dapat dikelola. Pengalaman
              bebas iklan tersedia kapan pun keluarga membutuhkannya.
            </div>
            <div style={{ display: "flex", gap: 16, marginTop: 40 }}>
              <Chip frame={frame} delay={25} accent={palette.green}>
                Data lokal
              </Chip>
              <Chip frame={frame} delay={31} accent={palette.gold}>
                Bebas iklan
              </Chip>
            </div>
          </div>
        </div>
      </AbsoluteFill>
    </SceneFrame>
  );
};

const Outro: React.FC<{ durationInFrames: number }> = ({
  durationInFrames,
}) => {
  const frame = useCurrentFrame();
  return (
    <SceneFrame durationInFrames={durationInFrames}>
      <AbsoluteFill
        style={{
          alignItems: "center",
          background: palette.ink,
          color: palette.cream,
          justifyContent: "center",
        }}
      >
        <GridGlow light />
        <div
          style={{
            alignItems: "center",
            display: "flex",
            flexDirection: "column",
            gap: 24,
            opacity: appear(frame),
            translate: `0px ${rise(frame, 42)}px`,
          }}
        >
          <BrandMark size={92} />
          <div style={{ fontSize: 66, fontWeight: 800, letterSpacing: -2 }}>
            Arunika
          </div>
          <div
            style={{ color: palette.goldSoft, fontSize: 30, fontWeight: 700 }}
          >
            Tumbuh kembang anak, lebih tenang.
          </div>
          <div style={{ color: "#c0cdc1", fontSize: 24, marginTop: 20 }}>
            Catat hari ini. Tumbuh bersama.
          </div>
        </div>
      </AbsoluteFill>
    </SceneFrame>
  );
};

export const ArunikaPromo: React.FC = () => {
  const { fps } = useVideoConfig();
  const intro = 4 * fps;
  const overview = 5 * fps;
  const chart = 6 * fps;
  const insight = 5 * fps;
  const wholeChild = 5 * fps;
  const privacy = 5 * fps;
  const outro = 4 * fps;

  return (
    <AbsoluteFill
      style={{ background: palette.ivory, fontFamily: "Arial, sans-serif" }}
    >
      <Sequence durationInFrames={intro} layout="none" name="01 Intro">
        <Intro durationInFrames={intro} />
      </Sequence>
      <Sequence
        from={intro}
        durationInFrames={overview}
        layout="none"
        name="02 Overview"
      >
        <Overview durationInFrames={overview} />
      </Sequence>
      <Sequence
        from={intro + overview}
        durationInFrames={chart}
        layout="none"
        name="03 Growth Chart"
      >
        <GrowthChart durationInFrames={chart} />
      </Sequence>
      <Sequence
        from={intro + overview + chart}
        durationInFrames={insight}
        layout="none"
        name="04 Insight"
      >
        <Insight durationInFrames={insight} />
      </Sequence>
      <Sequence
        from={intro + overview + chart + insight}
        durationInFrames={wholeChild}
        layout="none"
        name="05 Whole Child"
      >
        <WholeChild durationInFrames={wholeChild} />
      </Sequence>
      <Sequence
        from={intro + overview + chart + insight + wholeChild}
        durationInFrames={privacy}
        layout="none"
        name="06 Privacy"
      >
        <Privacy durationInFrames={privacy} />
      </Sequence>
      <Sequence
        from={intro + overview + chart + insight + wholeChild + privacy}
        durationInFrames={outro}
        layout="none"
        name="07 Outro"
      >
        <Outro durationInFrames={outro} />
      </Sequence>
    </AbsoluteFill>
  );
};

export const MyComposition = () => (
  <Composition
    id="ArunikaPromo"
    component={ArunikaPromo}
    durationInFrames={34 * 30}
    fps={30}
    height={1080}
    width={1920}
  />
);
