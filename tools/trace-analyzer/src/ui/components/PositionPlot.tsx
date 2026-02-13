import { useRef, useEffect, useMemo } from "react";
import type { SessionRecord, FunctionStreamEntry } from "../../core/types.js";
import { getStream, valueAt } from "../../core/emulator.js";

interface PositionPlotProps {
  session: SessionRecord;
  currentTime: number;
}

interface Point {
  x: number;
  y: number;
  t: number;
}

export function PositionPlot({ session, currentTime }: PositionPlotProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  // Extract all position points
  const { points, stream } = useMemo(() => {
    const s = getStream(session, "C_Map.GetPlayerMapPosition", "player");
    if (!s) return { points: [] as Point[], stream: undefined };

    const pts: Point[] = [];
    for (const entry of s as FunctionStreamEntry[]) {
      if (entry.v && typeof entry.v === "object") {
        const pos = entry.v as { x?: number; y?: number };
        if (typeof pos.x === "number" && typeof pos.y === "number") {
          pts.push({ x: pos.x, y: pos.y, t: entry.t });
        }
      }
    }
    return { points: pts, stream: s as FunctionStreamEntry[] };
  }, [session]);

  // Current position
  const currentPos = useMemo(() => {
    if (!stream) return null;
    const v = valueAt(stream, currentTime);
    if (v && typeof v === "object") {
      const pos = v as { x?: number; y?: number };
      if (typeof pos.x === "number" && typeof pos.y === "number") {
        return { x: pos.x, y: pos.y };
      }
    }
    return null;
  }, [stream, currentTime]);

  // Draw
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || points.length === 0) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    // Size canvas to container with WoW map aspect ratio (3:2)
    const MAP_ASPECT = 1.5;
    const rect = canvas.parentElement!.getBoundingClientRect();
    const maxW = rect.width - 20;
    const maxH = rect.height - 60;
    // Fit the 3:2 rectangle within available space
    let w = maxW;
    let h = w / MAP_ASPECT;
    if (h > maxH) {
      h = maxH;
      w = h * MAP_ASPECT;
    }
    canvas.width = w;
    canvas.height = h;

    // Fixed 0-1 bounds (WoW map coordinates are always 0-1)
    const pad = 30;

    const toCanvasX = (x: number) => pad + x * (w - 2 * pad);
    const toCanvasY = (y: number) => pad + y * (h - 2 * pad);

    // Clear
    ctx.fillStyle = "#1a1a2e";
    ctx.fillRect(0, 0, w, h);

    // Draw grid (lines at 0, 0.25, 0.50, 0.75, 1.0)
    ctx.strokeStyle = "#2a2a3e";
    ctx.lineWidth = 0.5;
    for (let i = 0; i <= 4; i++) {
      const cx = toCanvasX(i / 4);
      const cy = toCanvasY(i / 4);
      ctx.beginPath();
      ctx.moveTo(cx, pad);
      ctx.lineTo(cx, h - pad);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(pad, cy);
      ctx.lineTo(w - pad, cy);
      ctx.stroke();
    }

    // Time range for gradient
    const maxT = points[points.length - 1].t;

    // Draw path segments with time gradient
    for (let i = 1; i < points.length; i++) {
      const frac = points[i].t / (maxT || 1);
      // Blue (start) → Red (end)
      const r = Math.round(50 + 180 * frac);
      const g = Math.round(80 * (1 - frac));
      const b = Math.round(200 * (1 - frac));
      ctx.strokeStyle = `rgba(${r},${g},${b},0.6)`;
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.moveTo(toCanvasX(points[i - 1].x), toCanvasY(points[i - 1].y));
      ctx.lineTo(toCanvasX(points[i].x), toCanvasY(points[i].y));
      ctx.stroke();
    }

    // Draw current position
    if (currentPos) {
      const cx = toCanvasX(currentPos.x);
      const cy = toCanvasY(currentPos.y);

      // Glow
      ctx.beginPath();
      ctx.arc(cx, cy, 8, 0, Math.PI * 2);
      ctx.fillStyle = "rgba(255, 255, 100, 0.3)";
      ctx.fill();

      // Dot
      ctx.beginPath();
      ctx.arc(cx, cy, 4, 0, Math.PI * 2);
      ctx.fillStyle = "#ffff66";
      ctx.fill();
      ctx.strokeStyle = "#ffffff";
      ctx.lineWidth = 1;
      ctx.stroke();
    }

    // Axis labels
    ctx.fillStyle = "#666";
    ctx.font = "10px monospace";
    ctx.textAlign = "center";
    ctx.fillText("0", pad, h - 5);
    ctx.fillText("1", w - pad, h - 5);
    ctx.textAlign = "left";
    ctx.fillText("0", 2, pad - 5);
    ctx.fillText("1", 2, h - pad + 12);
    ctx.textAlign = "center";
    ctx.fillText("x", w / 2, h - 5);
    ctx.textAlign = "left";
    ctx.fillText("y", 2, h / 2);

    // Current coords overlay
    if (currentPos) {
      ctx.fillStyle = "#ccc";
      ctx.font = "12px monospace";
      ctx.textAlign = "right";
      ctx.fillText(
        `x: ${currentPos.x.toFixed(4)}, y: ${currentPos.y.toFixed(4)}`,
        w - 5,
        15
      );
    }
  }, [points, currentPos]);

  if (points.length === 0) {
    return (
      <div className="position-plot">
        <div className="stream-empty">No position data available</div>
      </div>
    );
  }

  return (
    <div className="position-plot">
      <div className="position-info">
        {points.length} position samples
        {currentPos && (
          <span>
            {" "}| Current: ({currentPos.x.toFixed(4)}, {currentPos.y.toFixed(4)})
          </span>
        )}
      </div>
      <canvas ref={canvasRef} />
    </div>
  );
}
