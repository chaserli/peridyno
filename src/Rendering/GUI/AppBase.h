#pragma once

#include <vector>
#include <memory>

#include "SceneGraphFactory.h"
#include "RenderEngine.h"

namespace dyno
{
	class SceneGraph;
	class RenderWindow;

	class AppBase {
	public:
		AppBase() {};
		~AppBase() {};

		virtual void initialize(int width, int height, bool usePlugin = false) {};
		virtual void mainLoop() = 0;

		virtual RenderWindow* renderWindow() { return nullptr; }

		virtual std::shared_ptr<SceneGraph> getSceneGraph() { return SceneGraphFactory::instance()->active(); }
		virtual void setSceneGraph(std::shared_ptr<SceneGraph> scene) { SceneGraphFactory::instance()->pushScene(scene); }

		virtual void setSceneGraphCreator(std::function<std::shared_ptr<SceneGraph>()> creator) { SceneGraphFactory::instance()->setDefaultCreator(creator); }
	};
}
