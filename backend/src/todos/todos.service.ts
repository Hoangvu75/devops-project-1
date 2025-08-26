import { Injectable } from '@nestjs/common';
import { CreateTodoDto } from './dto/create-todo.dto';
import { UpdateTodoDto } from './dto/update-todo.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Todo } from './entities/todo.entity';

@Injectable()
export class TodosService {
  constructor(
    @InjectRepository(Todo)
    private todosRepository: Repository<Todo>,
  ) {}

  create(createTodoDto: CreateTodoDto) {
    const newTodo = this.todosRepository.create(createTodoDto);
    return this.todosRepository.save(newTodo);
  }

  findAll() {
    return this.todosRepository.find();
  }

  findOne(id: number) {
    return this.todosRepository.findOneBy({ id });
  }

  async update(id: number, updateTodoDto: UpdateTodoDto) {
    await this.todosRepository.update(id, updateTodoDto);
    return this.findOne(id);
  }

  remove(id: number) {
    return this.todosRepository.delete(id);
  }
}
