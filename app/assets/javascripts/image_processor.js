const cropperOptions = {
  viewMode: 2,
  responsive: true,
  zoomable: false,
  autoCropArea: 1,
};

const setImageProperty = function(event) {
  document.getElementById('uploaded_image_crop_x').value = event.detail.x;
  document.getElementById('uploaded_image_crop_y').value = event.detail.y;
  document.getElementById('uploaded_image_crop_w').value = event.detail.width;
  document.getElementById('uploaded_image_crop_h').value = event.detail.height;
  document.getElementById('uploaded_image_rotate').value = event.detail.rotate;
  document.getElementById('uploaded_image_scale_x').value = event.detail.scaleX;
  document.getElementById('uploaded_image_scale_y').value = event.detail.scaleY;
};

// eslint-disable-next-line no-unused-vars
const ImageProcessor = (function() {
  return {
    initCropper: function(id) {
      this.image = document.getElementById(id);
      if (!this.image) return;
      cropper = new Cropper(this.image, {
        ...cropperOptions,
        crop(event) {
          setImageProperty(event);
        },
      });
    },
    flipX: function(ev) {
      const data = cropper.getData();
      cropper.scale(data.scaleX * -1, data.scaleY);
    },
    flipY: function(ev) {
      const data = cropper.getData();
      cropper.scale(data.scaleX, data.scaleY * -1);
    },
    rotate: function() {
      cropper.rotate(90);
    },
  };
})();
