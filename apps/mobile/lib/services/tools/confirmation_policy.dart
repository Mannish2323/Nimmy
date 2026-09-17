enum ActionRisk { readOnly, persistent, external, destructive, financial }

class ConfirmationPolicy {
  const ConfirmationPolicy();

  ActionRisk riskFor(String toolName) {
    return switch (toolName) {
      'create_reminder' || 'save_memory' || 'create_task' =>
        ActionRisk.persistent,
      'send_message' || 'share_content' => ActionRisk.external,
      'delete_memory' || 'delete_recording' => ActionRisk.destructive,
      'purchase' => ActionRisk.financial,
      _ => ActionRisk.readOnly,
    };
  }

  bool requiresConfirmation(String toolName) {
    return riskFor(toolName) != ActionRisk.readOnly;
  }
}
