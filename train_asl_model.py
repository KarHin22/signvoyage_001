import tensorflow as tf
import os
import argparse

# ---------------------------------------------------------
# ASL Alphabet TFLite Model Training Script
# 
# Usage:
# 1. Download the Kaggle ASL Alphabet Dataset:
#    https://www.kaggle.com/datasets/grassknoted/asl-alphabet
# 2. Extract it to a folder, e.g., 'asl_dataset/'
# 3. Run this script in your environment (or Kaggle Notebook):
#    python train_asl_model.py --data_dir ./asl_dataset/asl_alphabet_train/asl_alphabet_train
# 4. It will produce an 'asl_model.tflite' file.
# 5. Move 'asl_model.tflite' to your Flutter app's 'assets/' folder.
# ---------------------------------------------------------

def main(data_dir):
    print("Loading dataset from:", data_dir)
    
    batch_size = 32
    img_height = 224
    img_width = 224

    # Load dataset
    train_ds = tf.keras.preprocessing.image_dataset_from_directory(
      data_dir,
      validation_split=0.2,
      subset="training",
      seed=123,
      image_size=(img_height, img_width),
      batch_size=batch_size)

    val_ds = tf.keras.preprocessing.image_dataset_from_directory(
      data_dir,
      validation_split=0.2,
      subset="validation",
      seed=123,
      image_size=(img_height, img_width),
      batch_size=batch_size)

    class_names = train_ds.class_names
    print("Classes found:", class_names)
    num_classes = len(class_names)

    # Use MobileNetV2 as a lightweight base model for mobile
    base_model = tf.keras.applications.MobileNetV2(
        input_shape=(img_height, img_width, 3),
        include_top=False,
        weights='imagenet'
    )
    base_model.trainable = False # Freeze base model initially

    model = tf.keras.Sequential([
        tf.keras.layers.Rescaling(1./127.5, offset=-1, input_shape=(img_height, img_width, 3)),
        base_model,
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.Dropout(0.2),
        tf.keras.layers.Dense(num_classes, activation='softmax')
    ])

    model.compile(
      optimizer='adam',
      loss=tf.keras.losses.SparseCategoricalCrossentropy(),
      metrics=['accuracy'])

    print("Starting training (5 epochs)...")
    model.fit(
      train_ds,
      validation_data=val_ds,
      epochs=5
    )

    print("Training complete. Converting to TFLite...")
    
    # Convert to TFLite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    # Enable optimization for mobile size
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    # Save the model
    tflite_path = "asl_model.tflite"
    with open(tflite_path, 'wb') as f:
      f.write(tflite_model)
      
    print(f"Successfully saved TFLite model to {tflite_path}!")
    print("Move this file to your Flutter app's 'assets/' folder.")

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--data_dir', type=str, required=True, help='Path to Kaggle ASL Alphabet training images')
    args = parser.parse_args()
    main(args.data_dir)
