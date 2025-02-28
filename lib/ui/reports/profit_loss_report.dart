import 'package:built_collection/built_collection.dart';
import 'package:invoiceninja_flutter/utils/enums.dart';
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/company_model.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/reports/reports_state.dart';
import 'package:invoiceninja_flutter/redux/static/static_state.dart';
import 'package:invoiceninja_flutter/ui/reports/reports_screen.dart';
import 'package:memoize/memoize.dart';

enum ProfitAndLossReportFields {
  client,
  client_address1,
  client_address2,
  client_city,
  client_state,
  client_country,
  vendor,
  vendor_address1,
  vendor_address2,
  vendor_city,
  vendor_state,
  vendor_country,
  type,
  amount,
  date,
  category,
}

var memoizedProfitAndLossReport = memo9((
  UserCompanyEntity userCompany,
  ReportsUIState reportsUIState,
  BuiltMap<String, ClientEntity> clientMap,
  BuiltMap<String, PaymentEntity> paymentMap,
  BuiltMap<String, ExpenseEntity> expenseMap,
  BuiltMap<String, ExpenseCategoryEntity> expenseCategoryMap,
  BuiltMap<String, VendorEntity> vendorMap,
  BuiltMap<String, UserEntity> userMap,
  StaticState staticState,
) =>
    profitAndLossReport(
      userCompany,
      reportsUIState,
      clientMap,
      paymentMap,
      expenseMap,
      expenseCategoryMap,
      vendorMap,
      userMap,
      staticState,
    ));

ReportResult profitAndLossReport(
  UserCompanyEntity userCompany,
  ReportsUIState reportsUIState,
  BuiltMap<String, ClientEntity> clientMap,
  BuiltMap<String, PaymentEntity> paymentMap,
  BuiltMap<String, ExpenseEntity> expenseMap,
  BuiltMap<String, ExpenseCategoryEntity> expenseCategoryMap,
  BuiltMap<String, VendorEntity> vendorMap,
  BuiltMap<String, UserEntity> userMap,
  StaticState staticState,
) {
  final List<List<ReportElement>> data = [];
  BuiltList<ProfitAndLossReportFields> columns;

  final reportSettings = userCompany.settings.reportSettings;
  final profitAndLossReportSettings =
      reportSettings != null && reportSettings.containsKey(kReportProfitAndLoss)
          ? reportSettings[kReportProfitAndLoss]
          : ReportSettingsEntity();

  final defaultColumns = [
    ProfitAndLossReportFields.type,
    ProfitAndLossReportFields.amount,
    ProfitAndLossReportFields.client,
    ProfitAndLossReportFields.vendor,
    ProfitAndLossReportFields.date,
  ];

  if (profitAndLossReportSettings.columns.isNotEmpty) {
    columns = BuiltList(profitAndLossReportSettings.columns
        .map((e) => EnumUtils.fromString(ProfitAndLossReportFields.values, e))
        .where((element) => element != null)
        .toList());
  } else {
    columns = BuiltList(defaultColumns);
  }

  for (var paymentId in paymentMap.keys) {
    final payment = paymentMap[paymentId];
    final client = clientMap[payment.clientId] ?? ClientEntity();
    final vendor = vendorMap[payment.vendorId] ?? VendorEntity();

    bool skip = payment.isDeleted || client.isDeleted;
    final List<ReportElement> row = [];

    for (var column in columns) {
      dynamic value = '';

      switch (column) {
        case ProfitAndLossReportFields.type:
          value = EntityType.payment;
          break;
        case ProfitAndLossReportFields.client:
          value = client?.displayName;
          break;
        case ProfitAndLossReportFields.client_address1:
          value = client?.address1;
          break;
        case ProfitAndLossReportFields.client_address2:
          value = client?.address2;
          break;
        case ProfitAndLossReportFields.client_city:
          value = client?.city;
          break;
        case ProfitAndLossReportFields.client_state:
          value = client?.state;
          break;
        case ProfitAndLossReportFields.client_country:
          value = staticState.countryMap[client?.countryId]?.name ?? '';
          break;
        case ProfitAndLossReportFields.vendor:
          value = vendor?.listDisplayName;
          break;
        case ProfitAndLossReportFields.vendor_address1:
          value = vendor?.address1;
          break;
        case ProfitAndLossReportFields.vendor_address2:
          value = vendor?.address2;
          break;
        case ProfitAndLossReportFields.vendor_city:
          value = vendor?.city;
          break;
        case ProfitAndLossReportFields.vendor_state:
          value = vendor?.state;
          break;
        case ProfitAndLossReportFields.vendor_country:
          value = staticState.countryMap[vendor?.countryId]?.name ?? '';
          break;
        case ProfitAndLossReportFields.amount:
          value = payment?.amount;
          break;
        case ProfitAndLossReportFields.date:
          value = payment?.date;
          break;
        case ProfitAndLossReportFields.category:
          value = '';
          break;
      }

      if (!ReportResult.matchField(
        value: value,
        userCompany: userCompany,
        reportsUIState: reportsUIState,
        column: EnumUtils.parse(column),
      )) {
        skip = true;
      }

      if (value.runtimeType == EntityType) {
        row.add(payment.getReportEntityType());
      } else if (value.runtimeType == bool) {
        row.add(payment.getReportBool(value: value));
      } else if (value.runtimeType == double || value.runtimeType == int) {
        row.add(payment.getReportDouble(
            value: value, currencyId: payment.currencyId));
      } else {
        row.add(payment.getReportString(value: value));
      }
    }

    if (!skip) {
      data.add(row);
    }
  }

  for (var expenseId in expenseMap.keys) {
    final expense = expenseMap[expenseId];
    final client = clientMap[expense.clientId] ?? ClientEntity();
    final vendor = vendorMap[expense.vendorId] ?? VendorEntity();

    bool skip = expense.isDeleted || (client?.isDeleted ?? false);
    final List<ReportElement> row = [];

    for (var column in columns) {
      dynamic value = '';

      switch (column) {
        case ProfitAndLossReportFields.type:
          value = EntityType.expense;
          break;
        case ProfitAndLossReportFields.client:
          value = client?.displayName;
          break;
        case ProfitAndLossReportFields.client_address1:
          value = client?.address1;
          break;
        case ProfitAndLossReportFields.client_address2:
          value = client?.address2;
          break;
        case ProfitAndLossReportFields.client_city:
          value = client?.city;
          break;
        case ProfitAndLossReportFields.client_state:
          value = client?.state;
          break;
        case ProfitAndLossReportFields.client_country:
          value = staticState.countryMap[client?.countryId]?.name ?? '';
          break;
        case ProfitAndLossReportFields.vendor:
          value = vendor?.listDisplayName;
          break;
        case ProfitAndLossReportFields.vendor_address1:
          value = vendor?.address1;
          break;
        case ProfitAndLossReportFields.vendor_address2:
          value = vendor?.address2;
          break;
        case ProfitAndLossReportFields.vendor_city:
          value = vendor?.city;
          break;
        case ProfitAndLossReportFields.vendor_state:
          value = vendor?.state;
          break;
        case ProfitAndLossReportFields.vendor_country:
          value = staticState.countryMap[vendor?.countryId];
          break;
        case ProfitAndLossReportFields.amount:
          value = -expense.amount;
          break;
        case ProfitAndLossReportFields.date:
          value = expense.date;
          break;
        case ProfitAndLossReportFields.category:
          value = expenseCategoryMap[expense.categoryId]?.name ?? '';
          break;
      }

      if (!ReportResult.matchField(
        value: value,
        userCompany: userCompany,
        reportsUIState: reportsUIState,
        column: EnumUtils.parse(column),
      )) {
        skip = true;
      }

      if (value.runtimeType == EntityType) {
        row.add(expense.getReportEntityType());
      } else if (value.runtimeType == bool) {
        row.add(expense.getReportBool(value: value));
      } else if (value.runtimeType == double || value.runtimeType == int) {
        row.add(expense.getReportDouble(
            value: value, currencyId: expense.currencyId));
      } else {
        row.add(expense.getReportString(value: value));
      }
    }

    if (!skip) {
      data.add(row);
    }
  }

  final selectedColumns = columns.map((item) => EnumUtils.parse(item)).toList();
  data.sort((rowA, rowB) => sortReportTableRows(
      rowA, rowB, profitAndLossReportSettings, selectedColumns));

  return ReportResult(
    allColumns: ProfitAndLossReportFields.values
        .map((e) => EnumUtils.parse(e))
        .toList(),
    columns: columns.map((item) => EnumUtils.parse(item)).toList(),
    defaultColumns:
        defaultColumns.map((item) => EnumUtils.parse(item)).toList(),
    data: data,
  );
}
