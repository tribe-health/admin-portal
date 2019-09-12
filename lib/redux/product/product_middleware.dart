import 'package:flutter/material.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_middleware.dart';
import 'package:invoiceninja_flutter/redux/ui/ui_actions.dart';
import 'package:invoiceninja_flutter/redux/invoice/invoice_actions.dart';
import 'package:invoiceninja_flutter/ui/product/edit/product_edit_vm.dart';
import 'package:invoiceninja_flutter/ui/product/product_screen.dart';
import 'package:invoiceninja_flutter/ui/product/view/product_view_vm.dart';
import 'package:invoiceninja_flutter/utils/platforms.dart';
import 'package:redux/redux.dart';
import 'package:invoiceninja_flutter/redux/product/product_actions.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/data/repositories/product_repository.dart';

List<Middleware<AppState>> createStoreProductsMiddleware([
  ProductRepository repository = const ProductRepository(),
]) {
  final viewProductList = _viewProductList();
  final viewProduct = _viewProduct();
  final editProduct = _editProduct();
  final loadProducts = _loadProducts(repository);
  final saveProduct = _saveProduct(repository);
  final archiveProduct = _archiveProduct(repository);
  final deleteProduct = _deleteProduct(repository);
  final restoreProduct = _restoreProduct(repository);

  return [
    TypedMiddleware<AppState, ViewProductList>(viewProductList),
    TypedMiddleware<AppState, ViewProduct>(viewProduct),
    TypedMiddleware<AppState, EditProduct>(editProduct),
    TypedMiddleware<AppState, LoadProducts>(loadProducts),
    TypedMiddleware<AppState, SaveProductRequest>(saveProduct),
    TypedMiddleware<AppState, ArchiveProductRequest>(archiveProduct),
    TypedMiddleware<AppState, DeleteProductRequest>(deleteProduct),
    TypedMiddleware<AppState, RestoreProductRequest>(restoreProduct),
  ];
}

Middleware<AppState> _editProduct() {
  return (Store<AppState> store, dynamic dynamicAction,
      NextDispatcher next) async {
    final action = dynamicAction as EditProduct;

    if (hasChanges(
        store: store, context: action.context, force: action.force)) {
      return;
    }

    next(action);

    store.dispatch(UpdateCurrentRoute(ProductEditScreen.route));

    if (isMobile(action.context)) {
      Navigator.of(action.context).pushNamed(ProductEditScreen.route);
    }
  };
}

Middleware<AppState> _viewProduct() {
  return (Store<AppState> store, dynamic dynamicAction,
      NextDispatcher next) async {
    final action = dynamicAction as ViewProduct;

    if (hasChanges(
        store: store, context: action.context, force: action.force)) {
      return;
    }

    next(action);

    store.dispatch(UpdateCurrentRoute(ProductViewScreen.route));

    if (isMobile(action.context)) {
      Navigator.of(action.context).pushNamed(ProductViewScreen.route);
    }
  };
}

Middleware<AppState> _viewProductList() {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as ViewProductList;

    if (hasChanges(
        store: store, context: action.context, force: action.force)) {
      return;
    }

    next(action);

    store.dispatch(UpdateCurrentRoute(ProductScreen.route));

    if (isMobile(action.context)) {
      Navigator.of(action.context).pushNamedAndRemoveUntil(
          ProductScreen.route, (Route<dynamic> route) => false);
    }
  };
}

Middleware<AppState> _archiveProduct(ProductRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as ArchiveProductRequest;
    final origProduct = store.state.productState.map[action.productId];
    repository
        .saveData(store.state.credentials, origProduct, EntityAction.archive)
        .then((ProductEntity product) {
      store.dispatch(ArchiveProductSuccess(product));
      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((dynamic error) {
      print(error);
      store.dispatch(ArchiveProductFailure(origProduct));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}

Middleware<AppState> _deleteProduct(ProductRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as DeleteProductRequest;
    final origProduct = store.state.productState.map[action.productId];
    repository
        .saveData(store.state.credentials, origProduct, EntityAction.delete)
        .then((ProductEntity product) {
      store.dispatch(DeleteProductSuccess(product));
      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((Object error) {
      print(error);
      store.dispatch(DeleteProductFailure(origProduct));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}

Middleware<AppState> _restoreProduct(ProductRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as RestoreProductRequest;
    final origProduct = store.state.productState.map[action.productId];
    repository
        .saveData(store.state.credentials, origProduct, EntityAction.restore)
        .then((ProductEntity product) {
      store.dispatch(RestoreProductSuccess(product));
      if (action.completer != null) {
        action.completer.complete(null);
      }
    }).catchError((Object error) {
      print(error);
      store.dispatch(RestoreProductFailure(origProduct));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}

Middleware<AppState> _saveProduct(ProductRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as SaveProductRequest;
    repository
        .saveData(store.state.credentials, action.product)
        .then((ProductEntity product) {
      if (action.product.isNew) {
        store.dispatch(AddProductSuccess(product));
      } else {
        store.dispatch(SaveProductSuccess(product));
      }
      action.completer.complete(null);
    }).catchError((Object error) {
      print(error);
      store.dispatch(SaveProductFailure(error));
      action.completer.completeError(error);
    });

    next(action);
  };
}

Middleware<AppState> _loadProducts(ProductRepository repository) {
  return (Store<AppState> store, dynamic dynamicAction, NextDispatcher next) {
    final action = dynamicAction as LoadProducts;
    final AppState state = store.state;

    if (!state.productState.isStale && !action.force) {
      next(action);
      return;
    }

    if (state.isLoading) {
      next(action);
      return;
    }

    final int updatedAt = (state.productState.lastUpdated / 1000).round();

    store.dispatch(LoadProductsRequest());
    repository.loadList(store.state.credentials, updatedAt).then((data) {
      store.dispatch(LoadProductsSuccess(data));
      if (action.completer != null) {
        action.completer.complete(null);
      }
      if (state.invoiceState.isStale) {
        store.dispatch(LoadInvoices());
      }
    }).catchError((Object error) {
      print(error);
      store.dispatch(LoadProductsFailure(error));
      if (action.completer != null) {
        action.completer.completeError(error);
      }
    });

    next(action);
  };
}
