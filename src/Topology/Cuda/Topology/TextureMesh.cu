#include "TextureMesh.h"

namespace dyno
{
	TextureMesh::TextureMesh()
		: TopologyModule()
	{
	}

	TextureMesh::~TextureMesh()
	{
		this->clear();
	}

	template<typename Vec3f>
	__global__ void mergeVec3f(
		DArray<Vec3f> v0,
		DArray<Vec3f> v1,
		DArray<Vec3f> target,
		int sizeV0
	)
	{
		int pId = threadIdx.x + (blockIdx.x * blockDim.x);
		if (pId >= target.size()) return;

		if (pId < sizeV0)
			target[pId] = v0[pId];
		else
			target[pId] = v1[pId - sizeV0];
	}

	template<typename Vec2f>
	__global__ void mergeVec2f(
		DArray<Vec2f> v0,
		DArray<Vec2f> v1,
		DArray<Vec2f> target,
		int sizeV0
	)
	{
		int pId = threadIdx.x + (blockIdx.x * blockDim.x);
		if (pId >= target.size()) return;

		if (pId < sizeV0)
			target[pId] = v0[pId];
		else
			target[pId] = v1[pId - sizeV0];
	}

	__global__ void mergeUint(
		DArray<uint> v0,
		DArray<uint> v1,
		DArray<uint> target,
		int sizeV0
	)
	{
		int pId = threadIdx.x + (blockIdx.x * blockDim.x);
		if (pId >= target.size()) return;

		if (pId < sizeV0)
			target[pId] = v0[pId];
		else
			target[pId] = v1[pId - sizeV0];
	}

	__global__ void mergeShapeId(
		DArray<uint> v0,
		DArray<uint> v1,
		DArray<uint> target,
		int sizeV0,
		int shapeSize
	)
	{
		int pId = threadIdx.x + (blockIdx.x * blockDim.x);
		if (pId >= target.size()) return;

		if (pId < sizeV0)
			target[pId] = v0[pId];
		else
			target[pId] = v1[pId - sizeV0] + shapeSize;
	}

	template<typename Triangle>
	__global__ void updateVertexIndex(
		DArray<Triangle> v,
		DArray<Triangle> target,
		int offset
	)
	{
		int pId = threadIdx.x + (blockIdx.x * blockDim.x);
		if (pId >= target.size()) return;

		target[pId] = Triangle(v[pId][0] + offset, v[pId][1] + offset, v[pId][2] + offset);
	}

	void TextureMesh::merge(const std::shared_ptr<TextureMesh>& texMesh01, const std::shared_ptr<TextureMesh>& texMesh02)
	{
		auto vertices01 = texMesh01->vertices();
		auto vertices02 = texMesh02->vertices();

		this->vertices().resize(vertices01.size() + vertices02.size());

		cuExecute(this->vertices().size(),
			mergeVec3f,
			vertices01,
			vertices02,
			this->vertices(),
			vertices01.size()
		);

		auto normals01 = texMesh01->normals();
		auto normals02 = texMesh02->normals();
		this->normals().resize(normals01.size() + normals02.size());

		cuExecute(this->normals().size(),
			mergeVec3f,
			normals01,
			normals02,
			this->normals(),
			normals01.size()
		);

		auto texCoords01 = texMesh01->texCoords();
		auto texCoords02 = texMesh02->texCoords();
		this->texCoords().resize(texCoords01.size() + texCoords02.size());

		cuExecute(this->texCoords().size(),
			mergeVec2f,
			texCoords01,
			texCoords02,
			this->texCoords(),
			texCoords01.size()
		);

		auto shapeIds01 = texMesh01->shapeIds();
		auto shapeIds02 = texMesh02->shapeIds();
		this->shapeIds().resize(shapeIds01.size() + shapeIds02.size());

		cuExecute(this->texCoords().size(),
			mergeShapeId,
			shapeIds01,
			shapeIds02,
			this->shapeIds(),
			shapeIds01.size(),
			texMesh01->shapes().size()
		);


		auto material01 = texMesh01->materials();
		auto material02 = texMesh02->materials();

		auto outMaterials = this->materials();
		outMaterials.clear();

		for (auto it : material01)
			outMaterials.push_back(it);

		for (auto it : material02)
			outMaterials.push_back(it);


		auto shapes01 = texMesh01->shapes();
		auto shapes02 = texMesh02->shapes();

		std::vector<std::shared_ptr<Shape>> outShapes;

		for (auto it : shapes01)
		{
			auto element = std::make_shared<Shape>();
			element->vertexIndex.assign(it->vertexIndex);
			element->normalIndex.assign(it->normalIndex);
			element->texCoordIndex.assign(it->texCoordIndex);
			element->boundingBox = it->boundingBox;
			element->boundingTransform = it->boundingTransform;
			element->material = it->material;

			outShapes.push_back(element);
		}


		for (auto it : shapes02)
		{
			auto element = std::make_shared<Shape>();
			element->vertexIndex.assign(it->vertexIndex);
			element->normalIndex.assign(it->normalIndex);
			element->texCoordIndex.assign(it->texCoordIndex);
			element->boundingBox = it->boundingBox;
			element->boundingTransform = it->boundingTransform;
			element->material = it->material;

			outShapes.push_back(element);

			cuExecute(it->vertexIndex.size(),
				updateVertexIndex,
				it->vertexIndex,
				element->vertexIndex,
				vertices01.size()
			);

			cuExecute(it->normalIndex.size(),
				updateVertexIndex,
				it->normalIndex,
				element->normalIndex,
				normals01.size()
			);

			cuExecute(it->texCoordIndex.size(),
				updateVertexIndex,
				it->texCoordIndex,
				element->texCoordIndex,
				texCoords01.size()
			);

		}

		this->shapes() = outShapes;
		this->materials() = outMaterials;
	}

	void TextureMesh::clear()
	{
		mVertices.clear();
		mNormals.clear();
		mTexCoords.clear();
		mMaterials.clear();
		mShapeIds.clear();
		mShapes.clear();
	}

}