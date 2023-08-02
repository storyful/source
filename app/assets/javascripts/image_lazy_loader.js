var ImageLazyLoader = (function () {
  return {
    init: function(selector) {
      const imgs = document.querySelectorAll(selector);
      
      if (lazyLoadingUnsupported()) {
        loadAllImages(imgs);
      } else{
        lazyLoadImages(imgs);
      }
    }
  }
})();

function lazyLoadingUnsupported() {
  return !('IntersectionObserver' in window)
}

function loadAllImages(imgs){
  for (var i = 0; i < imgs.length; i++) {
    imgs[i].src =  imgs[i].getAttribute('data-url');
  }
}

function lazyLoadImages(imgs){
  let observer = new IntersectionObserver(loadImg);
  for (var i = 0; i < imgs.length; i++) {
    observer.observe(imgs[i]);
  }
}

function loadImg(changes) {
  changes.forEach(change => {
    if(change.intersectionRatio > 0){
      change.target.src = change.target.getAttribute('data-url');
    }
  })
}