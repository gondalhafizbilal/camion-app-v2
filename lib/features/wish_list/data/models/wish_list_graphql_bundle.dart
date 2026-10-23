import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/wish_list/data/models/get_wish_list_model.dart';

class WishListGraphqlBundle {
  const WishListGraphqlBundle({
    required this.wishLists,
    required this.popularProducts,
  });

  final List<GetWishListModel> wishLists;
  final List<HomeGraphqlProduct> popularProducts;
}
