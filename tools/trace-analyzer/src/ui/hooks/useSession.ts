import { useState, useEffect } from "react";
import type {
  SessionRecord,
  SessionSummary,
  TraceFileSummary,
} from "../../core/types.js";

export function useTraceFiles() {
  const [files, setFiles] = useState<TraceFileSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/files")
      .then((r) => r.json())
      .then((data) => {
        if (data.error) throw new Error(data.error);
        setFiles(data);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  return { files, loading, error };
}

export function useSessionList(fileName: string | null) {
  const [sessions, setSessions] = useState<SessionSummary[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!fileName) {
      setSessions([]);
      return;
    }
    setLoading(true);
    setError(null);
    fetch(`/api/file/${encodeURIComponent(fileName)}/sessions`)
      .then((r) => r.json())
      .then((data) => {
        if (data.error) throw new Error(data.error);
        setSessions(data);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [fileName]);

  return { sessions, loading, error };
}

export function useSession(fileName: string | null, sessionName: string | null) {
  const [session, setSession] = useState<SessionRecord | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!fileName || !sessionName) {
      setSession(null);
      return;
    }
    setLoading(true);
    setError(null);
    fetch(
      `/api/file/${encodeURIComponent(fileName)}/session/${encodeURIComponent(sessionName)}`
    )
      .then((r) => r.json())
      .then((data) => {
        if (data.error) throw new Error(data.error);
        setSession(data);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [fileName, sessionName]);

  return { session, loading, error };
}
