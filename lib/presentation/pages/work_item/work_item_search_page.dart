import 'package:flutter/material.dart';
import 'work_item_list_page.dart';

class WorkItemSearchPage extends StatelessWidget {
  final String workspaceSlug, projectId;
  const WorkItemSearchPage(
      {super.key, required this.workspaceSlug, required this.projectId});
  @override
  Widget build(BuildContext context) => WorkItemListPage(
      workspaceSlug: workspaceSlug, projectId: projectId, searchMode: true);
}
