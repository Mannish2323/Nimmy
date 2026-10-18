enum ActionRisk { readOnly, persistent, external, destructive, financial }

class ConfirmationPolicy {
  const ConfirmationPolicy();

  ActionRisk riskFor(String toolName) {
    return switch (toolName) {
      'create_reminder' ||
      'reschedule_reminder' ||
      'save_memory' ||
      'create_task' ||
      'edit_task' ||
      'reschedule_task' ||
      'complete_task' ||
      'create_calendar_event' ||
      'edit_calendar_event' ||
      'reschedule_calendar_event' => ActionRisk.persistent,
      'send_message' || 'share_content' => ActionRisk.external,
      'delete_memory' ||
      'delete_recording' ||
      'delete_reminder' ||
      'delete_task' ||
      'delete_calendar_event' => ActionRisk.destructive,
      'purchase' => ActionRisk.financial,
      _ => ActionRisk.readOnly,
    };
  }

  bool requiresConfirmation(String toolName) {
    return riskFor(toolName) != ActionRisk.readOnly;
  }
}
