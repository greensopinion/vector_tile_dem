import 'package:vector_tile_renderer/vector_tile_renderer.dart';

Theme contoursTheme() => ThemeReader().read(_themeJson());

Map<String, dynamic> _themeJson() => {
      "version": 8,
      "name": "Contours Style",
      "metadata": {"version": "19"},
      "sources": {
        "contour": {"type": "vector", "url": ""}
      },
      "layers": [
        {
          "id": "background",
          "type": "background",
          "paint": {"background-color": "#EEEEEE"}
        },
        {
          "id": "contour_medium",
          "type": "line",
          "source": "contour",
          "source-layer": "contours",
          "paint": {"line-color": "#ff0000", "line-width": 1.0}
        },
        // {
        //   "id": "elevation_label",
        //   "type": "symbol",
        //   "source": "contour",
        //   "source-layer": "contours",
        //   "minzoom": 12,
        //   "layout": {
        //     "symbol-placement": "line",
        //     "text-field": "{ele} level={level}",
        //     "visibility": "visible",
        //     "text-font": ["Roboto Regular"],
        //     "text-size": {
        //       "base": 1,
        //       "stops": [
        //         [13, 10],
        //         [14, 12],
        //         [18, 14]
        //       ]
        //     }
        //   },
        //   "paint": {"text-halo-color": "#EEEEEE", "text-color": "#81c784", "text-halo-width": 1}
        // }
      ],
      "id": "contours"
    };
