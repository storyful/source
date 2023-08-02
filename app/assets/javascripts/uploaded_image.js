function uploadImage() {
  let fileName = document.getElementById("uploaded_image_file").value;
  if(validFileType(fileName) && fileName.length >= 3){
    document.getElementById("overlay-upload-image").className += " visible";
    document.getElementById("new_uploaded_image").submit();
  }else{
    if(fileName.length >= 3) {
      let modal = M.Modal.init(document.querySelectorAll(".modal")[0], {});
      modal.open();
      document.getElementById("uploaded_image_file").value = "";
    }
  }
};

function analyseImage(){
  document.getElementById("overlay-analyse-image").className += " visible";
}

let fileTypes = [".png", ".jpg", ".jpeg", "gif"];
function validFileType(fileName){
  for (let i = 0; i < fileTypes.length; i++) {
    if( fileName.includes(fileTypes[i]) )
      return true
  }
  return false
}