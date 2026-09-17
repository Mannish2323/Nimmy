"use client";

import React, { useState } from "react";
import { X, CheckCircle2, AlertTriangle, MessageSquare, Send } from "lucide-react";
import { submitFeedback, submitCorrection } from "@/lib/api";

interface NimmyFeedbackModalProps {
  isOpen: boolean;
  onClose: () => void;
  messageText: string;
  messageId: string;
  onCorrectionApplied?: (correctionMessage: string) => void;
}

export const NimmyFeedbackModal: React.FC<NimmyFeedbackModalProps> = ({
  isOpen,
  onClose,
  messageText,
  messageId,
  onCorrectionApplied,
}) => {
  const [category, setCategory] = useState<
    "wrong_information" | "wrong_action" | "wrong_interpretation" | "wrong_memory" | "other"
  >("wrong_interpretation");
  const [correctionText, setCorrectionText] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!correctionText.trim() || isSubmitting) return;

    setIsSubmitting(true);

    try {
      // 1. Submit structured feedback
      await submitFeedback({
        session_id: "web-session",
        message_id: messageId,
        is_positive: false,
        error_category: category,
        feedback_text: messageText,
        suggested_correction: correctionText,
      });

      // 2. Submit correction to learning store
      const result = await submitCorrection(
        messageText,
        correctionText,
        category
      );

      setSubmitted(true);
      if (onCorrectionApplied) {
        onCorrectionApplied(result.response);
      }

      setTimeout(() => {
        setSubmitted(false);
        setCorrectionText("");
        onClose();
      }, 1400);
    } catch {
      setIsSubmitting(false);
    }
  };

  const categories = [
    { id: "wrong_interpretation", label: "Wrong Interpretation" },
    { id: "wrong_information", label: "Wrong Information" },
    { id: "wrong_action", label: "Wrong Action" },
    { id: "wrong_memory", label: "Wrong Memory" },
    { id: "other", label: "Other" },
  ] as const;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-fade-in">
      <div className="glass-panel-elevated w-full max-w-md rounded-2xl border border-white/10 p-6 space-y-4 shadow-2xl relative">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-zinc-400 hover:text-white transition-colors cursor-pointer"
        >
          <X className="w-4 h-4" />
        </button>

        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-lg bg-red-500/20 border border-red-500/30 flex items-center justify-center text-red-400">
            <AlertTriangle className="w-4 h-4" />
          </div>
          <div>
            <h3 className="text-sm font-bold text-white">Nimmy Galat Hai (Correction)</h3>
            <p className="text-[11px] text-zinc-400">Help Nimmy learn your correct intent & preferences</p>
          </div>
        </div>

        {submitted ? (
          <div className="py-8 flex flex-col items-center justify-center text-center space-y-2">
            <CheckCircle2 className="w-8 h-8 text-emerald-400 animate-bounce" />
            <p className="text-sm font-semibold text-white">Correction Learned</p>
            <p className="text-xs text-zinc-400">Nimmy has updated its context and will prioritize your correction.</p>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Context snippet */}
            <div className="p-3 rounded-xl bg-white/[0.03] border border-white/5 text-xs text-zinc-300 italic line-clamp-2">
              &quot;{messageText}&quot;
            </div>

            {/* Category selection */}
            <div>
              <label className="text-xs text-zinc-400 font-medium block mb-2">What was incorrect?</label>
              <div className="flex flex-wrap gap-1.5">
                {categories.map((cat) => (
                  <button
                    key={cat.id}
                    type="button"
                    onClick={() => setCategory(cat.id)}
                    className={`px-2.5 py-1 rounded-lg text-[11px] font-medium transition-colors cursor-pointer ${
                      category === cat.id
                        ? "bg-purple-600 text-white border border-purple-400/30"
                        : "glass-panel text-zinc-400 hover:text-zinc-200"
                    }`}
                  >
                    {cat.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Correction input */}
            <div>
              <label className="text-xs text-zinc-400 font-medium block mb-1">
                What should Nimmy have done or remembered?
              </label>
              <textarea
                rows={3}
                value={correctionText}
                onChange={(e) => setCorrectionText(e.target.value)}
                placeholder="e.g., 'Nahi, maine 9 PM bola tha' or 'I prefer concise answers by default'"
                className="w-full bg-white/[0.04] border border-white/10 rounded-xl p-3 text-xs text-white placeholder-zinc-500 focus:outline-none focus:border-purple-500/60 transition-colors"
                required
              />
            </div>

            <div className="flex items-center justify-end gap-2 pt-2">
              <button
                type="button"
                onClick={onClose}
                className="px-3.5 py-2 rounded-xl text-xs text-zinc-400 hover:text-white transition-colors cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={!correctionText.trim() || isSubmitting}
                className="px-4 py-2 rounded-xl bg-purple-600 hover:bg-purple-500 disabled:opacity-50 text-white text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer"
              >
                <Send className="w-3.5 h-3.5" />
                <span>{isSubmitting ? "Learning..." : "Submit Correction"}</span>
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
};
