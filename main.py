from selenium import webdriver
from time import sleep

txt = None
driver = webdriver.Firefox()
driver.get("https://www.shadertoy.com/view/fdGczD")
sleep(5)
while True:
    sleep(0.1)
    with open("shader.glsl") as file:    
        txt_new = file.read().replace("\n", "\\n")
        if txt_new == txt:
            continue
        txt = txt_new
        driver.execute_script(f"gShaderToy.mCodeEditor.setValue(`{txt}`)")
        driver.execute_script("gShaderToy.SetShaderFromEditor(false,true)")

