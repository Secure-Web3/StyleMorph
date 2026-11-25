import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

interface MailQueueDocument {
  to?: string;
  subject?: string;
  body?: string;
  eventType?: string;
  uid?: string;
  status?: string;
}

/**
 * Standalone, cost-controlled email dispatcher listening to `mail_queue/{mailId}`.
 * Dispatches emails via Resend API when `RESEND_API_KEY` is configured;
 * otherwise logs a graceful dry-run audit entry without failing.
 */
export const dispatchSensitiveEmail = onDocumentCreated(
  "mail_queue/{mailId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data() as MailQueueDocument;
    if (data.status !== "pending") {
      return;
    }

    const to = (data.to ?? "").trim();
    const subject = (data.subject ?? "").trim();
    const body = (data.body ?? "").trim();

    if (!to || !subject || !body) {
      await snap.ref.update({
        status: "failed",
        error: "Missing required email fields (to/subject/body).",
        processedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    const resendApiKey = process.env.RESEND_API_KEY?.trim();
    const fromEmail =
      process.env.MAIL_FROM_ADDRESS?.trim() ||
      "StyleMorph Security <no-reply@stylemorph.style>";

    if (!resendApiKey) {
      logger.info("[emailDispatcher] Dry-run (RESEND_API_KEY not configured)", {
        mailId: snap.id,
        to,
        subject,
        eventType: data.eventType ?? "general",
      });
      await snap.ref.update({
        status: "dry_run",
        processedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    try {
      const response = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${resendApiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: fromEmail,
          to: [to],
          subject,
          text: body,
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        logger.error("[emailDispatcher] Resend API failed", {
          mailId: snap.id,
          statusCode: response.status,
          errorText,
        });
        await snap.ref.update({
          status: "failed",
          error: `HTTP ${response.status}: ${errorText}`,
          processedAt: FieldValue.serverTimestamp(),
        });
        return;
      }

      await snap.ref.update({
        status: "sent",
        processedAt: FieldValue.serverTimestamp(),
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      logger.error("[emailDispatcher] Unexpected dispatch error", {
        mailId: snap.id,
        message,
      });
      await snap.ref.update({
        status: "failed",
        error: message,
        processedAt: FieldValue.serverTimestamp(),
      });
    }
  }
);
