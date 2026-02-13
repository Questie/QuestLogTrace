import { formatTime } from "../../core/emulator.js";

interface TimelineProps {
  duration: number;
  currentTime: number;
  playing: boolean;
  playSpeed: number;
  onSeek: (t: number) => void;
  onToggle: () => void;
  onSpeedChange: (speed: number) => void;
}

export function Timeline({
  duration,
  currentTime,
  playing,
  playSpeed,
  onSeek,
  onToggle,
  onSpeedChange,
}: TimelineProps) {
  return (
    <div className="timeline">
      <button className="timeline-btn" onClick={onToggle} title="Space to toggle">
        {playing ? "\u23F8" : "\u25B6"}
      </button>
      <select
        className="timeline-speed"
        value={playSpeed}
        onChange={(e) => onSpeedChange(Number(e.target.value))}
      >
        <option value={0.5}>0.5x</option>
        <option value={1}>1x</option>
        <option value={2}>2x</option>
        <option value={4}>4x</option>
        <option value={8}>8x</option>
      </select>
      <input
        className="timeline-slider"
        type="range"
        min={0}
        max={Math.round(duration * 1000)}
        step={1}
        value={Math.round(currentTime * 1000)}
        onChange={(e) => onSeek(Number(e.target.value) / 1000)}
      />
      <span className="timeline-time">
        {formatTime(currentTime)} / {formatTime(duration)}
      </span>
    </div>
  );
}
