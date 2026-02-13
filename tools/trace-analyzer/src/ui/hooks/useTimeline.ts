import { useState, useCallback, useEffect, useRef } from "react";

export function useTimeline(duration: number) {
  const [currentTime, setCurrentTime] = useState(0);
  const [playing, setPlaying] = useState(false);
  const [playSpeed, setPlaySpeed] = useState(1);
  const rafRef = useRef(0);
  const lastFrameRef = useRef(0);

  const play = useCallback(() => setPlaying(true), []);
  const pause = useCallback(() => setPlaying(false), []);
  const toggle = useCallback(() => setPlaying((p) => !p), []);

  const seek = useCallback(
    (t: number) => {
      setCurrentTime(Math.max(0, Math.min(duration, t)));
    },
    [duration]
  );

  const step = useCallback(
    (delta: number) => {
      setCurrentTime((t) => Math.max(0, Math.min(duration, t + delta)));
    },
    [duration]
  );

  // Animation loop
  useEffect(() => {
    if (!playing) return;
    lastFrameRef.current = performance.now();

    const animate = (now: number) => {
      const dt = ((now - lastFrameRef.current) / 1000) * playSpeed;
      lastFrameRef.current = now;
      setCurrentTime((t) => {
        const next = t + dt;
        if (next >= duration) {
          setPlaying(false);
          return duration;
        }
        return next;
      });
      rafRef.current = requestAnimationFrame(animate);
    };

    rafRef.current = requestAnimationFrame(animate);
    return () => cancelAnimationFrame(rafRef.current);
  }, [playing, duration, playSpeed]);

  // Keyboard controls
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      // Don't capture if user is typing in an input
      if (
        e.target instanceof HTMLInputElement ||
        e.target instanceof HTMLTextAreaElement
      )
        return;

      if (e.key === " ") {
        e.preventDefault();
        toggle();
      }
      if (e.key === "ArrowLeft") {
        e.preventDefault();
        step(e.shiftKey ? -10 : -1);
      }
      if (e.key === "ArrowRight") {
        e.preventDefault();
        step(e.shiftKey ? 10 : 1);
      }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [toggle, step]);

  return {
    currentTime,
    playing,
    playSpeed,
    play,
    pause,
    toggle,
    seek,
    step,
    setPlaySpeed,
  };
}
