# auto_resize_image

> Use it before:

![image-20210310212231175](https://tva1.sinaimg.cn/large/008eGmZEly1gof4kw7046j31la0hwgol.jpg)

> After use it:

![image-20210310213909407](https://tva1.sinaimg.cn/large/008eGmZEly1gof525iijfj30yu07wdga.jpg)

So just use it in your project!

It' s principle is same as `ResizeImage`，simplely use it like this:

```dart
Image(
  image: AutoResizeImage(
    NetworkImage(
      widget.imageUrl,
    ),
  ),
);
```

Just wrap your ImageProvider with it, it will reduce memory effectively.

Detail usage please read source code.

