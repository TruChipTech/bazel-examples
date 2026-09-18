def risky(value):
    # TODO: handle errors properly
    try:
        print("debugging", value)
        return value / 0
    except:
        return None
