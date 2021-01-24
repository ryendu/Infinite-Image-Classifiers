# Infinite-Image-Classifiers
> An easy, simple to use interface to train and use Image Classifiers
Click Here for the Video Demo.
## How to use
To train a Image Classifier with Infinite Image Classifiers, simply follow these steps:
1. navigate to the create image classifier view by clicking "Create Image Classifier" from the home screen
2. name your image classifier
3. add a few classes to classify images into then select images to add to those classes
4. select the number of iterations to train the ml model for
5. sit back, relax, see how its doing, and within no time the image classifier will be ready for you to save and use!

### Try it out quickly 
> for the Judge(s) of the Hack Your Portfolio Hackathon

Hello there **Judge(s)**! For you to quikly try it out, click on this link on an iOS device (Be aware that the link is only avalible for one device).

## How does it work
To create a image classifier, The following happens:
1. the user opens the app then setup a image classifier by naming it, selecting and labeling a few photos, and sets the iteration amount
2. once the user hits train, the app uploads all the information that the user entered to a Firebase Firestore database and makes an http request to the backend with the document id of the document in the firebase firestore database
3. the backend then checks out the document in the firestore database, reads all the information, downloads the photos from firebase storage, then preprocesses the photos, setups a transfer learning neural net using tensorflow, and trains it for the designated iterations while constantly sending back its progress to the app via updating the firestore document.
4. after the backend is done training, it will convert the tensorflow ml model into a .mlmodel, upload it to firebase storage, and notify the app that it has finished
5. once the backend is done doing its thing, the user can then export the .mlmodel file, and/or save the Image classifier in the app.

After the Image Classifer is saved on the app, the user can then go to the Machine Learning Portfolio page to find it, upload or take a photo, and use the image classifier to classify a new image!

## Components made before hand
There were a few parts of the project that I made before the hacakthon. That includes the following:
- the view for setting up, importing images, and preparing to train the image classifier
- the observation view for viewing the progress of the training
- the use image classifier view for using the finished image classifier.
- the preprocessing, the transfer learning setup, and the training pipeline for training the image classifier in the backend.

## Technologies Used
- Google Cloud Platform (GCP Kubernetes to be exact)
- Docker
- Flask for the backend
- Python
- Tensorflow
- Swift / SwiftUI for the app
- Firebase

## Want to Run Infinite Image Classifiers on your machine?
Theres are a few things you have to modify first. Heres a simple checklist:
1. clone the repo
2. place your GoogleService-Info.plist from your own Firebase Project at Infinite-Image-Classifiers/Infinite Image Classifier/Infinite Image Classifier/
3. place your GCP serviceAccountKey.json in the directory Infinite-Image-Classifiers/Backend/app/
4. place your Firebase-admin AdminServiceAccountKey.json in the directory Infinite-Image-Classifiers/Backend/app/
5. then, you can run it locally, dockerise it, build the app in xcode, etc.

## A little about me
My name is Ryan and I am a 14 year old teenager from Atlanta, Georgia in the 8th grade. I started learning programing two years ago, but I've only been really focused and into it starting from the Begining of Quarentine (March 2020). My skills include: Python, Swift, SwiftUI, Tensorflow with keras, Sklearn, and a little bit of javascript. You could reach out to me at ryandu9221@gmail.com
