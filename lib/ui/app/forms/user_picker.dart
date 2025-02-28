import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/data/models/entities.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/user/user_selectors.dart';
import 'package:invoiceninja_flutter/ui/app/forms/dynamic_selector.dart';

class UserPicker extends StatelessWidget {
  const UserPicker({this.userId, this.onChanged});

  final String userId;
  final Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final state = StoreProvider.of<AppState>(context).state;
    final userIds = memoizedUserList(state.userState.map);

    if (!state.userCompany.isAdmin || userIds.length == 1) {
      return SizedBox();
    }

    if (state.isHosted && !state.isEnterprisePlan) {
      return SizedBox();
    }

    return DynamicSelector(
      onChanged: onChanged,
      entityType: EntityType.user,
      entityId: userId,
      entityIds: userIds,
    );
  }
}
