#!/usr/bin/env python3

"""
A script to create a broken zip file
"""

import zipfile
from pathlib import Path

FILE_CONTENT = """Delectus quas cum et neque aperiam quibusdam consequuntur
aut. Architecto fugiat doloremque soluta saepe totam. Reprehenderit aut alias
quia placeat. Neque eius consequatur id est et. Aliquam et velit qui enim
cumque.

Suscipit cupiditate ea quisquam asperiores corrupti adipisci voluptatem illo.
Fugiat quis debitis earum recusandae nam ut. Qui velit eveniet maiores quas id
placeat.

Suscipit magni qui nesciunt perferendis quo in mollitia nesciunt. Tempore
delectus rem ducimus tempore temporibus consequatur rerum. Incidunt et aut a ut
et consequatur magni quod. Sed doloremque doloribus ipsam sunt libero et.

Aut quia similique quod cumque occaecati. Eaque libero sint nostrum fuga
suscipit quaerat ducimus. Dolorem quod sit corporis. Debitis veniam quae
eligendi ut autem voluptatibus saepe. Quis dolorem nostrum fugiat quos.

Et molestias at exercitationem vel rerum ex voluptate. Nihil eaque omnis
eveniet id cupiditate qui. Velit quibusdam nihil possimus voluptate quod
veniam. Est libero cum dolor consequatur ipsam est ut.
"""

def create_broken_zip():
    zip_path = Path("broken_zip.zip")

    if zip_path.exists():
        zip_path.unlink()

    test_file_name = "test_file"
    with zipfile.ZipFile(zip_path, "w") as zip_file:
        with zip_file.open(test_file_name, mode="w") as test_file:
            test_file.write(FILE_CONTENT.encode())
            test_file._crc = 0

    with zipfile.ZipFile(zip_path, "r") as zip_file:
        zip_info = zip_file.getinfo(test_file_name)
        print(f"Files with broken CRC in {zip_path}: {zip_file.testzip()}")


if __name__ == "__main__":
    create_broken_zip()
