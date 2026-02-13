import { useState, useMemo, useRef, useEffect } from "react";
import type { SessionRecord, EventEntry } from "../../core/types.js";
import {
  categorizeEvent,
  formatTime,
  isPackedArgs,
  type EventCategory,
} from "../../core/emulator.js";

interface EventLogProps {
  session: SessionRecord;
  currentTime: number;
  onSeek: (t: number) => void;
}

const CATEGORIES: { key: EventCategory; label: string }[] = [
  { key: "quest", label: "Quest" },
  { key: "loot", label: "Loot" },
  { key: "combat", label: "Combat" },
  { key: "chat", label: "Chat" },
  { key: "target", label: "Target" },
  { key: "zone", label: "Zone" },
  { key: "inventory", label: "Inv" },
  { key: "npc", label: "NPC" },
  { key: "init", label: "Init" },
  { key: "other", label: "Other" },
];

function formatArgs(a: unknown): string {
  if (!a || typeof a !== "object") return "";
  if (isPackedArgs(a)) {
    if (a.n === 0) return "";
    const items: string[] = [];
    for (let i = 1; i <= a.n; i++) {
      const val = (a as Record<number, unknown>)[i];
      if (val === null || val === undefined) items.push("nil");
      else if (typeof val === "string")
        items.push(val.length > 60 ? `"${val.slice(0, 57)}..."` : `"${val}"`);
      else items.push(String(val));
    }
    return items.join(", ");
  }
  return JSON.stringify(a);
}

function formatArgsPreview(a: unknown): string {
  const full = formatArgs(a);
  if (full.length > 80) return full.slice(0, 77) + "...";
  return full;
}

export function EventLog({ session, currentTime, onSeek }: EventLogProps) {
  const [filter, setFilter] = useState("");
  const [enabledCategories, setEnabledCategories] = useState<Set<EventCategory>>(
    () => new Set(CATEGORIES.map((c) => c.key))
  );
  const [expandedIdx, setExpandedIdx] = useState<number | null>(null);
  const [autoScroll, setAutoScroll] = useState(true);
  const listRef = useRef<HTMLDivElement>(null);
  const nearestRef = useRef<HTMLTableRowElement>(null);

  const toggleCategory = (cat: EventCategory) => {
    setEnabledCategories((prev) => {
      const next = new Set(prev);
      if (next.has(cat)) next.delete(cat);
      else next.add(cat);
      return next;
    });
  };

  // Filter events
  const filteredEvents = useMemo(() => {
    const lowerFilter = filter.toLowerCase();
    return session.events
      .map((event, idx) => ({ event, idx }))
      .filter(({ event }) => {
        if (!enabledCategories.has(categorizeEvent(event.e))) return false;
        if (filter && !event.e.toLowerCase().includes(lowerFilter)) return false;
        return true;
      });
  }, [session.events, enabledCategories, filter]);

  // Find nearest event to current time
  const nearestIdx = useMemo(() => {
    let best = -1;
    let bestDist = Infinity;
    for (let i = 0; i < filteredEvents.length; i++) {
      const dist = Math.abs(filteredEvents[i].event.t - currentTime);
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    return best;
  }, [filteredEvents, currentTime]);

  // Auto-scroll to nearest event
  useEffect(() => {
    if (autoScroll && nearestRef.current) {
      nearestRef.current.scrollIntoView({ block: "center", behavior: "auto" });
    }
  }, [nearestIdx, autoScroll]);

  return (
    <div className="event-log">
      {/* Controls */}
      <div className="event-controls">
        <input
          type="text"
          className="event-filter"
          placeholder="Filter events..."
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
        />
        <div className="event-categories">
          {CATEGORIES.map((cat) => (
            <label key={cat.key} className="category-toggle">
              <input
                type="checkbox"
                checked={enabledCategories.has(cat.key)}
                onChange={() => toggleCategory(cat.key)}
              />
              {cat.label}
            </label>
          ))}
        </div>
        <label className="auto-scroll-toggle">
          <input
            type="checkbox"
            checked={autoScroll}
            onChange={(e) => setAutoScroll(e.target.checked)}
          />
          Auto-scroll
        </label>
        <span className="event-count">
          {filteredEvents.length} / {session.events.length} events
        </span>
      </div>

      {/* Event list */}
      <div className="event-list" ref={listRef}>
        <table>
          <thead>
            <tr>
              <th className="col-time">Time</th>
              <th className="col-event">Event</th>
              <th className="col-args">Args</th>
            </tr>
          </thead>
          <tbody>
            {filteredEvents.map(({ event, idx }, filteredIdx) => {
              const isNearest = filteredIdx === nearestIdx;
              const isExpanded = expandedIdx === idx;
              const cat = categorizeEvent(event.e);
              return (
                <tr
                  key={idx}
                  ref={isNearest ? nearestRef : undefined}
                  className={`event-row cat-${cat} ${isNearest ? "nearest" : ""} ${isExpanded ? "expanded" : ""}`}
                  onClick={() => setExpandedIdx(isExpanded ? null : idx)}
                >
                  <td
                    className="col-time"
                    onClick={(e) => {
                      e.stopPropagation();
                      onSeek(event.t);
                    }}
                    title="Click to jump"
                  >
                    {formatTime(event.t)}
                  </td>
                  <td className="col-event">{event.e}</td>
                  <td className="col-args">
                    {isExpanded ? formatArgs(event.a) : formatArgsPreview(event.a)}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
