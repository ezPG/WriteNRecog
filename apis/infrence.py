import torch
import cv2 as cv
from model_class import make_model
import numpy as np
from pathlib import Path
import matplotlib.pyplot as plt


def get_device():
    return torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")


def load_model(MODEL_NAME):
    device = get_device()
    folder = ""
    PATH = Path(folder + MODEL_NAME)
    model = make_model().to(device)
    model.load_state_dict(torch.load(PATH, map_location=device))
    return model


def get_number():
    device = get_device()

    MODEL_NAME = "modelfinal.pt"
    model = load_model(MODEL_NAME)
    model.eval()

    image = cv.cvtColor(cv.imread("img.jpg"), cv.COLOR_BGR2GRAY)

    _, thresh = cv.threshold(image, 0, 128, cv.THRESH_OTSU + cv.THRESH_BINARY_INV)

    contours, hierarchy = cv.findContours(
        thresh, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE
    )


    # print(len(hl) ,len(l))
    digits = []
    for cnt in contours:
        area = cv.contourArea(cnt)
        if area > 1000:
            digits.append(cnt)
            # print(cnt)

    # print("dig")
    # print(len(digits), len(digits[0]))
    seg_img = np.zeros_like(image)
    hl = []
    l = []
    for cnt in digits:
        x, y, w, h = cv.boundingRect(cnt)
        cv.rectangle(image, (x, y), (x + w, y + h), (0, 255, 0), 2)
        l.append([[x, x + w], [y, y + h]])

    l.sort()

    # print(l)
    plt.imshow(image)
    plt.show()


    # print(len(hl) , len(l))

    nums = []

    for i in range(len(l)):
        # print(i)
        p1 = thresh[l[i][1][0] : l[i][1][1] + 1, l[i][0][0] : l[i][0][1] + 1]
        # non_zeros = np.count_nonzero(p1)
        # print(non_zeros)
        # print((p1.shape[0]*p1.shape[1]) - non_zeros)
        # if non_zeros > ((p1.shape[0]*p1.shape[1]) - non_zeros):
        #     continue
        pad_size = 40
        # plt.imshow(p1, cmap = 'gray')
        # plt.show()
        jk = np.pad(p1, ((pad_size, pad_size), (pad_size, pad_size)), mode="constant")
        k1 = cv.resize(jk, (28, 28))
        nums.append(k1)
        phone_number = ""
        for num in nums:
            num = torch.from_numpy(num)
            num = num.to(torch.float32)
            num = num.unsqueeze(0)
            _, y_pred = model(num.to(device))

            phone_number += str(y_pred.argmax().cpu().numpy())

    return phone_number


# phone_number = get_number()


# print(phone_number)
