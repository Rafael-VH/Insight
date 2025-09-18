abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ImagePickerFailure extends Failure {
  const ImagePickerFailure(super.message);
}

class TextRecognitionFailure extends Failure {
  const TextRecognitionFailure(super.message);
}

class FileSystemFailure extends Failure {
  const FileSystemFailure(super.message);
}
