import { useState, useMemo } from "react";
import type { SessionRecord, FunctionStream, FunctionStreamEntry, FunctionStreamMap } from "../../core/types.js";
import {
  isParameterless,
  getParamKeys,
  getStream,
  valueAt,
  activeIndex,
  emulate,
  isPackedArgs,
  formatTime,
} from "../../core/emulator.js";
import { getSchema, type ReturnField } from "../../core/function-schemas.js";

interface StreamViewerProps {
  session: SessionRecord;
  currentTime: number;
  onSeek: (t: number) => void;
}

/** Format a scalar value for display */
function formatScalar(v: unknown): string {
  if (v === undefined || v === null) return "nil";
  if (typeof v === "string") return `"${v}"`;
  if (typeof v === "number") return String(v);
  if (typeof v === "boolean") return String(v);
  return String(v);
}

/** Format a value for display (flat string, used for previews and unlabeled contexts) */
function formatValue(v: unknown): string {
  if (v === undefined || v === null) return "nil";
  if (typeof v === "string") return `"${v}"`;
  if (typeof v === "number") return String(v);
  if (typeof v === "boolean") return String(v);

  if (Array.isArray(v)) {
    const items = v.map((item) =>
      item === null || item === undefined ? "nil" : formatValue(item)
    );
    return `(${items.join(", ")})`;
  }

  if (typeof v === "object") {
    if (isPackedArgs(v)) {
      const items: string[] = [];
      for (let i = 1; i <= v.n; i++) {
        const val = (v as Record<number, unknown>)[i];
        items.push(val === null || val === undefined ? "nil" : formatValue(val));
      }
      return `(${items.join(", ")})`;
    }
    // Plain object
    const entries = Object.entries(v as Record<string, unknown>);
    if (entries.length === 0) return "{}";
    const items = entries.map(([k, val]) => `${k}: ${formatValue(val)}`);
    return `{ ${items.join(", ")} }`;
  }

  return String(v);
}

/** Extract array items from an emulated value (array or packed args) */
function toArray(v: unknown): unknown[] | undefined {
  if (Array.isArray(v)) return v;
  if (v && typeof v === "object" && isPackedArgs(v)) {
    const result: unknown[] = [];
    for (let i = 1; i <= v.n; i++) {
      result.push((v as Record<number, unknown>)[i] ?? null);
    }
    return result;
  }
  return undefined;
}

/** Labeled value display — renders a vertical table of name: value pairs */
function LabeledValue({ value, schema }: { value: unknown; schema: ReturnField[] }) {
  const items = toArray(value);
  if (!items) return <span>{formatValue(value)}</span>;

  return (
    <table className="labeled-value">
      <tbody>
        {schema.map((field, i) => {
          const val = i < items.length ? items[i] : undefined;
          const isNil = val === undefined || val === null;
          return (
            <tr key={field.name}>
              <td className="field-name">{field.name}</td>
              <td className={`field-value ${isNil ? "nil-value" : ""}`}>
                {formatScalar(val)}
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}

/** Stream list item */
function StreamItem({
  name,
  param,
  selected,
  entryCount,
  currentValue,
  onClick,
}: {
  name: string;
  param?: string;
  selected: boolean;
  entryCount: number;
  currentValue: string;
  onClick: () => void;
}) {
  const displayName = param !== undefined ? `  ${param}` : name;
  const valuePreview =
    currentValue.length > 40
      ? currentValue.slice(0, 37) + "..."
      : currentValue;

  return (
    <div
      className={`stream-item ${selected ? "selected" : ""} ${param !== undefined ? "stream-param" : ""}`}
      onClick={onClick}
    >
      <span className="stream-name">{displayName}</span>
      <span className="stream-count">{entryCount}</span>
      <span className={`stream-preview ${currentValue === "nil" ? "nil-value" : ""}`}>
        {valuePreview}
      </span>
    </div>
  );
}

/** Full history table for a selected stream */
function StreamHistory({
  stream,
  activeIdx,
  onSeek,
  schema,
}: {
  stream: FunctionStreamEntry[];
  activeIdx: number;
  onSeek: (t: number) => void;
  schema?: ReturnField[];
}) {
  return (
    <table className="stream-history">
      <thead>
        <tr>
          <th>t</th>
          <th>tp</th>
          <th>value</th>
        </tr>
      </thead>
      <tbody>
        {stream.map((entry, i) => {
          const val = entry.v !== undefined ? emulate(entry.v) : undefined;
          return (
            <tr
              key={i}
              className={i === activeIdx ? "active-entry" : ""}
              onClick={() => onSeek(entry.t)}
              style={{ cursor: "pointer" }}
            >
              <td className="time-cell">{formatTime(entry.t)}</td>
              <td className="time-cell">{formatTime(entry.tp)}</td>
              <td className={entry.v === undefined ? "nil-value" : ""}>
                {schema ? (
                  <LabeledValue value={val} schema={schema} />
                ) : (
                  formatValue(val)
                )}
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}

/** Delta stream viewer */
function DeltaViewer({
  session,
  currentTime,
  onSeek,
}: {
  session: SessionRecord;
  currentTime: number;
  onSeek: (t: number) => void;
}) {
  const deltaKeys = Object.keys(session.functionsDelta);
  if (deltaKeys.length === 0) return null;

  return (
    <div className="delta-section">
      <div className="section-header">Delta Streams</div>
      {deltaKeys.map((key) => {
        const ds = session.functionsDelta[key];
        // Build current set
        const currentSet = new Set<number>(ds.initial);
        for (const d of ds.delta) {
          if (d.t > currentTime) break;
          if (d.add) for (const id of d.add) currentSet.add(id);
          if (d.remove) for (const id of d.remove) currentSet.delete(id);
        }
        return (
          <div key={key} className="delta-stream">
            <div className="stream-name">{key}</div>
            <div className="delta-info">
              Initial: {ds.initial.length} items | Current:{" "}
              {currentSet.size} items | Deltas: {ds.delta.length}
            </div>
            {ds.delta.length > 0 && (
              <table className="stream-history">
                <thead>
                  <tr>
                    <th>t</th>
                    <th>change</th>
                  </tr>
                </thead>
                <tbody>
                  {ds.delta.map((d, i) => (
                    <tr
                      key={i}
                      className={d.t <= currentTime ? "active-entry" : ""}
                      onClick={() => onSeek(d.t)}
                      style={{ cursor: "pointer" }}
                    >
                      <td className="time-cell">{formatTime(d.t)}</td>
                      <td>
                        {d.add && d.add.length > 0 && (
                          <span className="delta-add">
                            +[{d.add.join(", ")}]
                          </span>
                        )}
                        {d.remove && d.remove.length > 0 && (
                          <span className="delta-remove">
                            -[{d.remove.join(", ")}]
                          </span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        );
      })}
    </div>
  );
}

function streamPathKey(functionName: string, params: string[]): string {
  return [functionName, ...params].join("\u0000");
}

function streamDisplayName(functionName: string, params: string[]): string {
  return `${functionName}${params.map((param) => `[${param}]`).join("")}`;
}

function samePath(left: string[], right: string[]): boolean {
  if (left.length !== right.length) return false;
  for (let i = 0; i < left.length; i++) {
    if (left[i] !== right[i]) return false;
  }
  return true;
}

/** Sorts Lua table keys in the order users expect for numeric params. */
function compareParamKeys(left: string, right: string): number {
  const leftNumber = Number(left);
  const rightNumber = Number(right);
  const leftIsNumeric = left.trim() !== "" && Number.isFinite(leftNumber);
  const rightIsNumeric = right.trim() !== "" && Number.isFinite(rightNumber);

  if (leftIsNumeric && rightIsNumeric && leftNumber !== rightNumber) {
    return leftNumber - rightNumber;
  }
  return left.localeCompare(right);
}

/**
 * Renders one node in the function stream tree.
 *
 * Parameter maps are expandable groups. Only leaf arrays can be selected for
 * value lookup/history, which keeps nested parameter streams compatible with the
 * existing one-level stream viewer behavior.
 */
function StreamTreeNode({
  functionName,
  node,
  params,
  depth,
  currentTime,
  selectedKey,
  selectedParams,
  expandedKeys,
  onToggle,
  onSelect,
}: {
  functionName: string;
  node: FunctionStream;
  params: string[];
  depth: number;
  currentTime: number;
  selectedKey: string | null;
  selectedParams: string[];
  expandedKeys: Set<string>;
  onToggle: (pathKey: string) => void;
  onSelect: (functionName: string, params: string[]) => void;
}) {
  const indent = "  ".repeat(depth);

  if (isParameterless(node)) {
    const isSelected = selectedKey === functionName && samePath(selectedParams, params);
    const val = valueAt(node, currentTime);
    // Leaf rows show only their final param; the detail header shows the full path.
    const lastParam = params.length > 0 ? `${indent}[${params[params.length - 1]}]` : undefined;
    return (
      <StreamItem
        key={streamPathKey(functionName, params)}
        name={functionName}
        param={lastParam}
        selected={isSelected}
        entryCount={node.length}
        currentValue={formatValue(val !== undefined ? emulate(val) : undefined)}
        onClick={() => onSelect(functionName, params)}
      />
    );
  }

  const pathKey = streamPathKey(functionName, params);
  // Preserve numeric API argument order for params like rewardIndex before questId.
  const childKeys = getParamKeys(node).sort(compareParamKeys);
  const isExpanded = expandedKeys.has(pathKey);
  const label = params.length === 0 ? functionName : `${indent}[${params[params.length - 1]}]`;

  return (
    <div key={pathKey}>
      <div className="stream-item stream-group" onClick={() => onToggle(pathKey)}>
        <span className="stream-name">
          {isExpanded ? "\u25BE" : "\u25B8"} {label}
        </span>
        <span className="stream-count">{childKeys.length} params</span>
      </div>
      {isExpanded &&
        childKeys.map((param) => (
          <StreamTreeNode
            key={streamPathKey(functionName, [...params, param])}
            functionName={functionName}
            node={(node as FunctionStreamMap)[param]}
            params={[...params, param]}
            depth={depth + 1}
            currentTime={currentTime}
            selectedKey={selectedKey}
            selectedParams={selectedParams}
            expandedKeys={expandedKeys}
            onToggle={onToggle}
            onSelect={onSelect}
          />
        ))}
    </div>
  );
}

export function StreamViewer({ session, currentTime, onSeek }: StreamViewerProps) {
  const [filter, setFilter] = useState("");
  const [selectedKey, setSelectedKey] = useState<string | null>(null);
  const [selectedParams, setSelectedParams] = useState<string[]>([]);
  const [expandedKeys, setExpandedKeys] = useState<Set<string>>(new Set());

  // Build the list of function keys
  const functionKeys = useMemo(() => {
    const keys = Object.keys(session.functions).sort();
    if (!filter) return keys;
    const lowerFilter = filter.toLowerCase();
    return keys.filter((k) => k.toLowerCase().includes(lowerFilter));
  }, [session.functions, filter]);

  const toggleExpand = (pathKey: string) => {
    setExpandedKeys((prev) => {
      const next = new Set(prev);
      if (next.has(pathKey)) next.delete(pathKey);
      else next.add(pathKey);
      return next;
    });
  };

  const selectStream = (key: string, params: string[] = []) => {
    setSelectedKey(key);
    setSelectedParams(params);
  };

  const selectedPathKey = useMemo(
    () => (selectedKey ? streamPathKey(selectedKey, selectedParams) : ""),
    [selectedKey, selectedParams]
  );

  // Get the currently selected stream
  const selectedStream = useMemo(() => {
    if (!selectedKey) return undefined;
    return getStream(session, selectedKey, ...selectedParams);
  }, [session, selectedKey, selectedPathKey]);

  const currentVal = useMemo(() => {
    if (!selectedStream) return undefined;
    const raw = valueAt(selectedStream, currentTime);
    return raw !== undefined ? emulate(raw) : undefined;
  }, [selectedStream, currentTime]);

  const activeIdx = useMemo(() => {
    if (!selectedStream) return -1;
    return activeIndex(selectedStream, currentTime);
  }, [selectedStream, currentTime]);

  // Resolve the schema for the selected function
  const schema = useMemo(() => {
    if (!selectedKey) return undefined;
    return getSchema(selectedKey);
  }, [selectedKey]);

  return (
    <div className="stream-viewer">
      {/* Left panel: function list */}
      <div className="stream-list">
        <input
          className="stream-filter"
          type="text"
          placeholder="Filter functions..."
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
        />
        <div className="stream-list-items">
          {functionKeys.map((key) => (
            <StreamTreeNode
              key={key}
              functionName={key}
              node={session.functions[key]}
              params={[]}
              depth={0}
              currentTime={currentTime}
              selectedKey={selectedKey}
              selectedParams={selectedParams}
              expandedKeys={expandedKeys}
              onToggle={toggleExpand}
              onSelect={selectStream}
            />
          ))}
        </div>
        <DeltaViewer
          session={session}
          currentTime={currentTime}
          onSeek={onSeek}
        />
      </div>

      {/* Right panel: selected stream detail */}
      <div className="stream-detail">
        {!selectedKey && (
          <div className="stream-empty">Select a function stream to inspect</div>
        )}
        {selectedKey && selectedStream && (
          <>
            <div className="stream-detail-header">
              <span className="stream-detail-name">
                {streamDisplayName(selectedKey, selectedParams)}
              </span>
              <span className="stream-detail-count">
                {selectedStream.length} entries
              </span>
            </div>
            <div className="stream-detail-current">
              <div className="label">Value at {formatTime(currentTime)}:</div>
              <div
                className={`current-value ${currentVal === undefined ? "nil-value" : ""}`}
              >
                {schema ? (
                  <LabeledValue value={currentVal} schema={schema} />
                ) : (
                  formatValue(currentVal)
                )}
              </div>
            </div>
            <div className="stream-detail-history">
              <div className="label">Full History:</div>
              <StreamHistory
                stream={selectedStream}
                activeIdx={activeIdx}
                onSeek={onSeek}
                schema={schema}
              />
            </div>
          </>
        )}
        {selectedKey && !selectedStream && (
          <div className="stream-empty">No data for this stream</div>
        )}
      </div>
    </div>
  );
}
