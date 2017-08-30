rm *.java
rm *.class
rm *.tokens
java -cp "D:\Software\Antlr\antlr-4.7-complete.jar" org.antlr.v4.Tool MATLAB.g4
javac *.java
