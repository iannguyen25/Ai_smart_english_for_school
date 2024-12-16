import 'package:images_picker/images_picker.dart';

List<String> pickImage = <String>[
  'Gallery',
  'Camera',
];

Future getImage(
    {required String type,
    required Function(List<Media>?) onClick,
    int? maxFile}) async {
  List<Media>? newPicker;

  if (type == pickImage[0]) {
    newPicker = await ImagesPicker.pick(
        pickType: PickType.image, quality: 0.9, count: maxFile ?? 10);
  } else {
    newPicker =
        await ImagesPicker.openCamera(pickType: PickType.image, quality: 0.9);
  }
  onClick(newPicker);
}
