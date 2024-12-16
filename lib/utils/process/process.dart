class ProcessApp{
    int indexOfList({required List<dynamic> data,required dynamic value}){
      for(int i=0; i< data.length; i++){
        if(data[i]==value) return i;
      }
      return 0;
    }
}