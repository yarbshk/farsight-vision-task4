#!/usr/bin/env python3
"""
Downloads all files from a public Google Drive folder.

This script exists because it does not seem possible to download large public folder automatically
without some kind of authentication.

Get a free API key at: https://console.developers.google.com
1. Create project
2. Enable Google Drive API
3. Add API Key credentials
"""

import logging
import os
import requests
import argparse

class GoogleDriveService:
	def __init__(self, api_key):
		self._api_key = api_key
		self._session = requests.Session()

	def list_files(self, folder_id):
		files = []
		page_token = None

		while True:
			params = {
				"q": f"'{folder_id}' in parents",
				"key": self._api_key,
				"fields": "nextPageToken, files(id, name)",
				"pageSize": 100,
			}
			if page_token:
				params["pageToken"] = page_token

			request = requests.get("https://www.googleapis.com/drive/v3/files", params=params)
			request.raise_for_status()
			data = request.json()

			files.extend(data.get("files", []))
			page_token = data.get("nextPageToken")
			if not page_token:
				break

		files.sort(key=lambda x: x["name"])

		return files

	def download_file(self, file_id, file_name, output_dir):
		url = f"https://drive.google.com/uc?export=download&id={file_id}"
		request = self._session.get(url, stream=True)
		
		# A workaround to be able to download more than 50 files in a row
		token = request.cookies.get("download_warning")
		if token:
			request = self._session.get(url, params={"confirm": token}, stream=True)
		
		path = os.path.join(output_dir, file_name)
		with open(path, "wb") as file:
			for chunk in request.iter_content(chunk_size=8192):
				file.write(chunk)


def main():
	logging.basicConfig(level=logging.INFO)

	parser = argparse.ArgumentParser(
		description="Download files from a public Google Drive folder",
		usage="Usage: ./download-dataset.py",
	)
	parser.add_argument("--folder-id", required=True, help="Google Drive folder ID")
	parser.add_argument("--output-dir", default="./downloads", help="Output directory (default: ./downloads)")
	args = parser.parse_args()

	API_KEY = os.environ.get("GOOGLE_API_KEY")
	if not API_KEY:
		logging.error("Please set the GOOGLE_API_KEY environment variable")
		exit(1)

	os.makedirs(args.output_dir, exist_ok=True)

	gdrive = GoogleDriveService(API_KEY)
	files = gdrive.list_files(args.folder_id)
	logging.info(f"Found {len(files)} files")

	for i, file in enumerate(files, 1):
		logging.info(f"[{i}/{len(files)}] {file['name']}")
		gdrive.download_file(file["id"], file["name"], args.output_dir)

	logging.info("Done.")


if __name__ == "__main__":
	main()
